import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/network/api_client.dart';
import '../data/repositories/viaje_repository.dart';
import '../models/viaje_model.dart';

/// ViewModel de viajes (MVVM).
/// - El backend (MongoDB) es la fuente de verdad: POST /api/viajes y GET /api/viajes.
/// - SharedPreferences: caché sin conexión y "viajes en curso".
/// - Viaje "en curso": el servidor deja de devolverlo cuando el viajero acepta
///   una encomienda. La app lo sigue mostrando (desde la caché) hasta que el
///   usuario lo cierre con 🗑️ o hasta que pase su fecha.
class ViajeViewModel extends ChangeNotifier {
  final ViajeRepository _repo;
  ViajeViewModel({ViajeRepository? repo}) : _repo = repo ?? ViajeRepository();

  // ---------------- Estado ----------------
  final List<ViajeModel> _viajes = [];
  bool _cargandoLista = false;
  bool _validando = false;
  bool _guardando = false;
  String? _errorLista;
  VueloInfo? _vueloValidado;

  /// Estados que significan que el viaje ya terminó (no se muestran).
  static const List<String> _estadosCerrados = [
    'completado',
    'finalizado',
    'cerrado',
    'cancelado',
    'inactivo',
  ];

  // ---------------- Getters para la UI ----------------
  List<ViajeModel> get viajes => _viajes;
  bool get cargandoLista => _cargandoLista;
  bool get validando => _validando;
  bool get guardando => _guardando;
  String? get errorLista => _errorLista;
  VueloInfo? get vueloValidado => _vueloValidado;

  /// Se mantiene por compatibilidad; siempre false.
  bool get cierreSoloLocal => false;

  String _limpiar(Object e) =>
      e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // ---------------- Caché local ----------------
  String _cacheKey() => 'cache_viajes_$_uid';
  String _cerradosKey() => 'viajes_cerrados_$_uid';

  Future<void> _guardarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey(), jsonEncode(_viajes.map((v) => v.toJson()).toList()));
    } catch (_) {}
  }

  Future<List<ViajeModel>> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey());
      if (str == null || str.isEmpty) return [];
      return (jsonDecode(str) as List)
          .map((j) => ViajeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ids de viajes que el usuario cerró (no deben volver a aparecer).
  Future<Set<String>> _cerrados() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cerradosKey()) ?? []).toSet();
  }

  Future<void> _marcarCerrado(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await _cerrados()..add(id);
    await prefs.setStringList(_cerradosKey(), set.toList());
  }

  /// Borra la lista vieja de "viajes ocultos" de la versión anterior.
  Future<void> _borrarOcultosViejos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('viajes_ocultos_$_uid');
    } catch (_) {}
  }

  // ---------------- Mis viajes ----------------

  /// Viajes del backend + viajes "en curso" que el backend ya no devuelve.
  Future<void> cargarMisViajes() async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();
    try {
      await _borrarOcultosViejos();
      final delServidor = await _repo.misViajes();
      final idsServidor = delServidor.map((v) => v.id).toSet();
      final cerrados = await _cerrados();
      final anteriores = await _leerCache();

      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);

      // Estaban antes, el servidor ya no los devuelve, no los cerró el usuario
      // y su fecha no ha pasado → siguen "en curso".
      final enCurso = anteriores
          .where((v) =>
      v.id.isNotEmpty &&
          !idsServidor.contains(v.id) &&
          !cerrados.contains(v.id) &&
          (v.fecha == null || !v.fecha!.isBefore(inicioHoy)))
          .map((v) => ViajeModel(
        id: v.id,
        numeroVuelo: v.numeroVuelo,
        fecha: v.fecha,
        origen: v.origen,
        destino: v.destino,
        estado: 'en_curso',
      ));

      _viajes
        ..clear()
        ..addAll(delServidor.where((v) =>
        !_estadosCerrados.contains(v.estado.toLowerCase()) &&
            !cerrados.contains(v.id)))
        ..addAll(enCurso);
      await _guardarCache();
    } catch (e) {
      _errorLista = _limpiar(e);
      if (_viajes.isEmpty) _viajes.addAll(await _leerCache());
    } finally {
      _cargandoLista = false;
      notifyListeners();
    }
  }

  // ---------------- Validar vuelo ----------------

  /// GET /api/vuelos/:numero/:fecha. Devuelve null si es válido, o el error.
  Future<String?> validarVuelo(String numero, String fecha) async {
    _validando = true;
    _vueloValidado = null;
    notifyListeners();
    try {
      _vueloValidado = await _repo.validarVuelo(numero, fecha);
      return null;
    } on ApiException catch (e) {
      return e.statusCode == 404
          ? 'No encontramos el vuelo $numero para esa fecha.'
          : _limpiar(e);
    } catch (e) {
      return _limpiar(e);
    } finally {
      _validando = false;
      notifyListeners();
    }
  }

  void resetValidacion() {
    if (_vueloValidado != null) {
      _vueloValidado = null;
      notifyListeners();
    }
  }

  // ---------------- Registrar viaje ----------------

  /// POST /api/viajes y recarga la lista desde el backend.
  Future<String?> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    _guardando = true;
    notifyListeners();

    final yaExiste = _viajes.any((v) =>
    v.numeroVuelo.trim().toUpperCase() == numeroVuelo.trim().toUpperCase() &&
        v.origen.trim().toLowerCase() == origen.trim().toLowerCase() &&
        v.destino.trim().toLowerCase() == destino.trim().toLowerCase());

    if (yaExiste) {
      _guardando = false;
      notifyListeners();
      return 'Ya tienes registrado un viaje activo para el vuelo $numeroVuelo en la ruta $origen ➔ $destino.';
    }

    try {
      await _repo.registrarViaje(
          numeroVuelo: numeroVuelo, fecha: fecha, origen: origen, destino: destino);
      _vueloValidado = null;
      await cargarMisViajes();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.message.toLowerCase().contains('viaje disponible')) {
        return 'Ya tienes un viaje disponible. Vuelve a "Viajes", toca ese viaje '
            'y presiona 🗑️ → Cerrar viaje para poder registrar uno nuevo.';
      }
      return _limpiar(e);
    } catch (e) {
      return _limpiar(e);
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  // ---------------- Cerrar viaje ----------------

  /// Cierra el viaje en el servidor y lo marca como cerrado en el celular.
  /// Si es un viaje "en curso" que el servidor ya no reconoce, igual se quita.
  Future<String?> eliminarViaje(String id) async {
    final esEnCurso = _viajes.any((v) => v.id == id && v.estado == 'en_curso');
    try {
      await _repo.cerrarViaje(id);
    } on ApiException catch (e) {
      if (!(esEnCurso && e.statusCode == 404)) {
        return e.statusCode == 404
            ? 'El servidor no permitió cerrar este viaje. Intenta de nuevo más tarde.'
            : _limpiar(e);
      }
    } catch (e) {
      return _limpiar(e);
    }
    await _marcarCerrado(id);
    _viajes.removeWhere((v) => v.id == id);
    await _guardarCache();
    await cargarMisViajes();
    return null;
  }
}
