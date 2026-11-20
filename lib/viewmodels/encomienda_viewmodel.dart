import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/encomienda_repository.dart';
import '../models/encomienda_model.dart';

class EncomiendaViewModel extends ChangeNotifier {
  final EncomiendaRepository _repository;

  final List<EncomiendaModel> _misEncomiendas = [];
  List<EncomiendaModel> _encomiendasDisponiblesRuta = [];
  bool _isLoading = false;
  String? _errorMessage;

  EncomiendaViewModel({EncomiendaRepository? repository})
      : _repository = repository ?? EncomiendaRepository();

  List<EncomiendaModel> get misEncomiendas => _misEncomiendas;
  List<EncomiendaModel> get encomiendasDisponiblesRuta => _encomiendasDisponiblesRuta;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _cacheKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'cache_encomiendas_$uid';
  }

  Future<void> _guardarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _misEncomiendas.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey(), jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> _cargarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey());
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List;
        final list = decoded.map((j) => EncomiendaModel.fromJson(j as Map<String, dynamic>)).toList();
        for (var item in list) {
          if (!_misEncomiendas.any((e) => e.id == item.id)) {
            _misEncomiendas.add(item);
          }
        }
      }
    } catch (_) {}
  }

  /// Publicar nueva encomienda como Remitente
  Future<bool> crearEncomienda({
    required String origen,
    required String destino,
    required String descripcion,
    required String peso,
    required double valorPagar,
    required String fechaVencimiento,
    required String nombreRemitente,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nueva = await _repository.crearEncomienda(
        origen: origen,
        destino: destino,
        descripcion: descripcion,
        peso: peso,
        valorPagar: valorPagar,
        fechaVencimiento: fechaVencimiento,
        nombreRemitente: nombreRemitente,
      );

      if (!_misEncomiendas.any((e) => e.id == nueva.id)) {
        _misEncomiendas.insert(0, nueva);
      }
      await _guardarCache();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cargar encomiendas del remitente
  /// Mis encomiendas desde el backend (la caché solo si no hay conexión).
  Future<void> cargarMisEncomiendas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _repository.obtenerMisEncomiendas();
      _misEncomiendas
        ..clear()
        ..addAll(list);
      await _guardarCache();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      if (_misEncomiendas.isEmpty) await _cargarCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// MATCH: encomiendas de OTROS usuarios con la misma ruta del viaje.
  /// Las propias se excluyen comparando su _id con "mis encomiendas",
  /// porque /disponibles no trae el uid del remitente.
  Future<void> buscarEncomiendasParaViajero({
    required String origen,
    required String destino,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    String norm(String s) => s.trim().toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u');

    try {
      Set<String> idsMias = {};
      try {
        idsMias = (await _repository.obtenerMisEncomiendas()).map((e) => e.id).toSet();
      } catch (_) {}

      final list = await _repository.obtenerEncomiendasDisponibles(origen: origen, destino: destino);

      _encomiendasDisponiblesRuta = list.where((e) =>
      !idsMias.contains(e.id) &&
          (currentUid == null || e.uidRemitente != currentUid) &&
          norm(e.origen) == norm(origen) &&
          norm(e.destino) == norm(destino) &&
          (e.estaDisponible || (e.estaTomada && e.uidViajero == currentUid))).toList();
    } catch (e) {
      _encomiendasDisponiblesRuta = [];
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Acción del Viajero: Aceptar llevar una encomienda
  Future<bool> tomarEncomienda({
    required EncomiendaModel encomienda,
    required String viajeroNombre,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.tomarEncomienda(
        id: encomienda.id,
        viajeroNombre: viajeroNombre,
      );

      if (success) {
        final index = _encomiendasDisponiblesRuta.indexWhere((e) => e.id == encomienda.id);
        if (index != -1) {
          _encomiendasDisponiblesRuta[index] = _encomiendasDisponiblesRuta[index].copyWith(
            estado: 'tomada',
            nombreViajero: viajeroNombre,
          );
        }

        final myIndex = _misEncomiendas.indexWhere((e) => e.id == encomienda.id);
        if (myIndex != -1) {
          _misEncomiendas[myIndex] = _misEncomiendas[myIndex].copyWith(
            estado: 'tomada',
            nombreViajero: viajeroNombre,
          );
        }
        await _guardarCache();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
