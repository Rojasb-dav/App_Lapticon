import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/network/api_client.dart';
import '../data/repositories/viaje_repository.dart';
import '../models/viaje_model.dart';

/// ViewModel de viajes (MVVM).
/// - El backend (MongoDB) es la fuente de verdad: POST /api/viajes y GET /api/viajes.
/// - SharedPreferences solo es caché (sin conexión) y lista de viajes ocultos.
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

  /// true si el último "eliminar" solo ocultó el viaje en este celular
  /// (porque el servidor aún no tiene ruta para cerrarlo).
  bool _cierreSoloLocal = false;

  /// Estados que significan que el viaje ya terminó (no se muestran).
  static const List<String> _estadosCerrados = ['completado', 'finalizado', 'cerrado', 'cancelado'];

  // ---------------- Getters para la UI ----------------
  List<ViajeModel> get viajes => _viajes;
  bool get cargandoLista => _cargandoLista;
  bool get validando => _validando;
  bool get guardando => _guardando;
  String? get errorLista => _errorLista;
  VueloInfo? get vueloValidado => _vueloValidado;
  bool get cierreSoloLocal => _cierreSoloLocal;

  /// Quita los prefijos técnicos para mostrar un mensaje limpio.
  String _limpiar(Object e) =>
      e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // ---------------- Caché local ----------------
  String _cacheKey() => 'cache_viajes_$_uid';
  String _ocultosKey() => 'viajes_ocultos_$_uid';

  Future<void> _guardarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(), jsonEncode(_viajes.map((v) => v.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _cargarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey());
      if (str != null && str.isNotEmpty) {
        final list = (jsonDecode(str) as List)
            .map((j) => ViajeModel.fromJson(j as Map<String, dynamic>));
        for (final item in list) {
          if (!_viajes.any((v) => v.id == item.id)) _viajes.add(item);
        }
      }
    } catch (_) {}
  }

  /// Ids de viajes ocultos en este celular.
  Future<Set<String>> _ocultos() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_ocultosKey()) ?? []).toSet();
  }

  // ---------------- Mis viajes ----------------

  /// Trae los viajes del backend; no muestra los cerrados ni los ocultos.
  Future<void> cargarMisViajes() async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();
    try {
      final lista = await _repo.misViajes();
      final ocultos = await _ocultos();
      _viajes
        ..clear()
        ..addAll(lista.where((v) =>
        !_estadosCerrados.contains(v.estado.toLowerCase()) && !ocultos.contains(v.id)));
      await _guardarCache();
    } catch (e) {
      _errorLista = _limpiar(e);
      if (_viajes.isEmpty) await _cargarCache();
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

  /// Si cambia el número o la fecha, hay que validar de nuevo.
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
    } catch (e) {
      return _limpiar(e);
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  // ---------------- Eliminar / cerrar viaje ----------------

  /// 1) Intenta cerrar el viaje en el backend (PUT /api/viajes/:id/estado).
  /// 2) Si esa ruta no existe (404), lo oculta en este celular como antes.
  Future<String?> eliminarViaje(String id) async {
    _cierreSoloLocal = false;
    try {
      await _repo.cerrarViaje(id);
    } on ApiException catch (e) {
      if (e.statusCode != 404) return _limpiar(e);
      final prefs = await SharedPreferences.getInstance();
      final ocultos = await _ocultos()..add(id);
      await prefs.setStringList(_ocultosKey(), ocultos.toList());
      _cierreSoloLocal = true;
    } catch (e) {
      return _limpiar(e);
    }
    await cargarMisViajes();
    return null;
  }
}
