import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/encomienda_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../models/encomienda_model.dart';

/// ViewModel de encomiendas (MVVM).
/// - Backend: crear, mis encomiendas, disponibles por ruta, tomar y eliminar.
/// - Firestore: registra a la remitente en el chat y guarda las encomiendas
///   eliminadas para ocultarlas a todos (si el servidor no permite borrarlas).
class EncomiendaViewModel extends ChangeNotifier {
  final EncomiendaRepository _repository;
  final ChatRepository _chatRepo;

  final List<EncomiendaModel> _misEncomiendas = [];
  List<EncomiendaModel> _encomiendasDisponiblesRuta = [];
  Set<String> _canceladas = {};
  bool _isLoading = false;
  String? _errorMessage;

  EncomiendaViewModel({EncomiendaRepository? repository, ChatRepository? chatRepo})
      : _repository = repository ?? EncomiendaRepository(),
        _chatRepo = chatRepo ?? ChatRepository();

  List<EncomiendaModel> get misEncomiendas => _misEncomiendas;
  List<EncomiendaModel> get encomiendasDisponiblesRuta => _encomiendasDisponiblesRuta;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _limpiar(Object e) =>
      e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');

  // ---------------- Caché local ----------------
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

  Future<List<EncomiendaModel>> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey());
      if (str == null || str.isEmpty) return [];
      return (jsonDecode(str) as List)
          .map((j) => EncomiendaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Trae de Firestore las encomiendas eliminadas (si falla, usa las conocidas).
  Future<void> _cargarCanceladas() async {
    try {
      _canceladas = await _chatRepo.obtenerCanceladas();
    } catch (e) {
      debugPrint('No se pudieron leer las encomiendas canceladas: $e');
    }
  }

  // ---------------- Chat: registrar a la remitente ----------------

  Future<void> _registrarChats(List<EncomiendaModel> lista, {String? nombre}) async {
    for (final e in lista) {
      if (e.id.isEmpty) continue;
      try {
        await _chatRepo.registrarComoRemitente(
          chatId: e.id,
          nombreRemitente: nombre ?? e.nombreRemitente,
          ruta: '${e.origen} → ${e.destino}',
        );
      } catch (err) {
        debugPrint('No se pudo registrar el chat de ${e.id}: $err');
      }
    }
  }

  // ---------------- Crear ----------------

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
      if (nueva.id.isNotEmpty && !_misEncomiendas.any((e) => e.id == nueva.id)) {
        _misEncomiendas.insert(0, nueva);
      }
      await _guardarCache();
      _registrarChats([nueva], nombre: nombreRemitente);
      return true;
    } catch (e) {
      _errorMessage = _limpiar(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Mis encomiendas ----------------

  Future<void> cargarMisEncomiendas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _cargarCanceladas();
    final enCache =
    (await _leerCache()).where((e) => !_canceladas.contains(e.id)).toList();
    try {
      final list = (await _repository.obtenerMisEncomiendas())
          .where((e) => !_canceladas.contains(e.id))
          .toList();
      _misEncomiendas
        ..clear()
        ..addAll(list);
      await _guardarCache();
      _registrarChats(
          [...list, ...enCache.where((c) => !list.any((l) => l.id == c.id))]);
    } catch (e) {
      _errorMessage = _limpiar(e);
      if (_misEncomiendas.isEmpty) _misEncomiendas.addAll(enCache);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Eliminar (remitente) ----------------

  /// Elimina una encomienda que nadie ha aceptado.
  /// 1) Intenta borrarla en el servidor. 2) La marca como cancelada en Firestore
  /// para que ningún viajero la vea. Devuelve null si salió bien, o el error.
  Future<String?> eliminarEncomienda(EncomiendaModel enc) async {
    if (enc.id.isEmpty) {
      return 'Esta encomienda aún no tiene identificador. Desliza para actualizar.';
    }
    _isLoading = true;
    notifyListeners();
    try {
      // Seguridad: si ya hay viajero, no se elimina.
      try {
        if (await _chatRepo.tieneViajero(enc.id)) {
          return 'Un viajero ya aceptó esta encomienda; no se puede eliminar.';
        }
      } catch (_) {}

      var servidorOk = true;
      try {
        await _repository.eliminarEncomienda(enc.id);
        debugPrint('✅ Encomienda eliminada en el servidor');
      } catch (e) {
        servidorOk = false;
        debugPrint('El servidor no permitió eliminar ($e); se cancela en Firestore.');
      }

      try {
        await _chatRepo.marcarCancelada(enc.id);
      } catch (e) {
        if (!servidorOk) return 'No se pudo eliminar: ${_limpiar(e)}';
      }

      _canceladas.add(enc.id);
      _misEncomiendas.removeWhere((e) => e.id == enc.id);
      _encomiendasDisponiblesRuta.removeWhere((e) => e.id == enc.id);
      await _guardarCache();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Match (viajero) ----------------

  /// Encomiendas de OTROS usuarios en la ruta, sin las propias ni las eliminadas.
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
      await _cargarCanceladas();
      Set<String> idsMias = {};
      try {
        idsMias = (await _repository.obtenerMisEncomiendas()).map((e) => e.id).toSet();
      } catch (_) {}

      final list = await _repository.obtenerEncomiendasDisponibles(
          origen: origen, destino: destino);

      _encomiendasDisponiblesRuta = list.where((e) =>
      !_canceladas.contains(e.id) &&
          !idsMias.contains(e.id) &&
          (currentUid == null || e.uidRemitente != currentUid) &&
          norm(e.origen) == norm(origen) &&
          norm(e.destino) == norm(destino) &&
          (e.estaDisponible || (e.estaTomada && e.uidViajero == currentUid))).toList();
    } catch (e) {
      _encomiendasDisponiblesRuta = [];
      _errorMessage = _limpiar(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// El viajero acepta llevar una encomienda (PUT /api/encomiendas/tomar/:id).
  Future<bool> tomarEncomienda({
    required EncomiendaModel encomienda,
    required String viajeroNombre,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_canceladas.contains(encomienda.id)) {
        _errorMessage = 'Esta encomienda fue eliminada por su remitente.';
        return false;
      }
      await _repository.tomarEncomienda(id: encomienda.id, viajeroNombre: viajeroNombre);

      final i = _encomiendasDisponiblesRuta.indexWhere((e) => e.id == encomienda.id);
      if (i != -1) {
        _encomiendasDisponiblesRuta[i] = _encomiendasDisponiblesRuta[i].copyWith(
          estado: 'tomada',
          uidViajero: FirebaseAuth.instance.currentUser?.uid,
          nombreViajero: viajeroNombre,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = _limpiar(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
