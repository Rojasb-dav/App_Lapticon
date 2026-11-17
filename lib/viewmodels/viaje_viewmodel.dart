import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/network/api_client.dart';
import '../data/repositories/viaje_repository.dart';
import '../models/viaje_model.dart';

class ViajeViewModel extends ChangeNotifier {
  final ViajeRepository _repo;
  ViajeViewModel({ViajeRepository? repo}) : _repo = repo ?? ViajeRepository();

  final List<ViajeModel> _viajes = [];
  bool _cargandoLista = false;
  bool _validando = false;
  bool _guardando = false;
  String? _errorLista;
  VueloInfo? _vueloValidado;

  List<ViajeModel> get viajes => _viajes;
  bool get cargandoLista => _cargandoLista;
  bool get validando => _validando;
  bool get guardando => _guardando;
  String? get errorLista => _errorLista;
  VueloInfo? get vueloValidado => _vueloValidado;

  String _limpiar(Object e) =>
      e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');

  String _cacheKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'cache_viajes_$uid';
  }

  Future<void> _guardarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _viajes.map((v) => v.toJson()).toList();
      await prefs.setString(_cacheKey(), jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> _cargarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey());
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List;
        final list = decoded.map((j) => ViajeModel.fromJson(j as Map<String, dynamic>)).toList();
        for (var item in list) {
          if (!_viajes.any((v) => v.id == item.id)) {
            _viajes.add(item);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> cargarMisViajes() async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();

    await _cargarCache();

    try {
      final backendList = await _repo.misViajes();
      for (var item in backendList) {
        if (!_viajes.any((v) => v.id == item.id)) {
          _viajes.add(item);
        }
      }
      await _guardarCache();
    } catch (e) {
      _errorLista = _limpiar(e);
    } finally {
      _cargandoLista = false;
      notifyListeners();
    }
  }

  /// Devuelve null si el vuelo es válido, o el mensaje de error
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

  Future<String?> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    _guardando = true;
    notifyListeners();
    try {
      await _repo.registrarViaje(
          numeroVuelo: numeroVuelo, fecha: fecha, origen: origen, destino: destino);
      _vueloValidado = null;

      final nuevoViaje = ViajeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        numeroVuelo: numeroVuelo,
        fecha: DateTime.tryParse(fecha),
        origen: origen,
        destino: destino,
        estado: 'activo',
      );

      if (!_viajes.any((v) => v.numeroVuelo == numeroVuelo && v.origen == origen && v.destino == destino)) {
        _viajes.insert(0, nuevoViaje);
      }

      await _guardarCache();
      return null;
    } catch (e) {
      return _limpiar(e);
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
