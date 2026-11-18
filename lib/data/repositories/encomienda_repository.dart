import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/encomienda_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class EncomiendaRepository {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;

  static const String _publicSharedKey = 'shared_public_encomiendas';

  EncomiendaRepository({ApiClient? apiClient, FirebaseAuth? firebaseAuth})
      : _apiClient = apiClient ?? ApiClient(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  List<dynamic> _extraerLista(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      if (res['encomiendas'] is List) return res['encomiendas'];
      if (res['data'] is List) return res['data'];
      if (res['result'] is List) return res['result'];
      if (res['items'] is List) return res['items'];
    }
    return [];
  }

  Future<void> _guardarEnSharedPublic(EncomiendaModel encomienda) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_publicSharedKey);
      List<dynamic> listJson = [];
      if (str != null && str.isNotEmpty) {
        listJson = jsonDecode(str) as List;
      }
      final newMap = encomienda.toJson();
      listJson.removeWhere((item) => (item['id'] ?? item['_id']) == encomienda.id);
      listJson.insert(0, newMap);
      await prefs.setString(_publicSharedKey, jsonEncode(listJson));
    } catch (_) {}
  }

  Future<List<EncomiendaModel>> _obtenerDeSharedPublic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_publicSharedKey);
      if (str != null && str.isNotEmpty) {
        final listJson = jsonDecode(str) as List;
        return listJson.map((e) => EncomiendaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Crear una nueva encomienda POST /api/encomiendas
  Future<EncomiendaModel> crearEncomienda({
    required String origen,
    required String destino,
    required String descripcion,
    required String peso,
    required double valorPagar,
    required String fechaVencimiento,
    required String nombreRemitente,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No hay sesión de usuario activa.');

    final payload = {
      'uidRemitente': user.uid,
      'nombreRemitente': nombreRemitente,
      'origen': origen,
      'destino': destino,
      'descripcion': descripcion,
      'peso': peso,
      'valorPagar': valorPagar,
      'fechaVencimiento': fechaVencimiento,
      'estado': 'disponible',
    };

    EncomiendaModel encomiendaCreada;

    try {
      final res = await _apiClient.post(ApiConstants.encomiendas, payload);
      if (res is Map<String, dynamic>) {
        encomiendaCreada = EncomiendaModel.fromJson(res);
      } else {
        encomiendaCreada = EncomiendaModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          uidRemitente: user.uid,
          nombreRemitente: nombreRemitente,
          origen: origen,
          destino: destino,
          descripcion: descripcion,
          peso: peso,
          valorPagar: valorPagar,
          fechaVencimiento: fechaVencimiento,
          estado: 'disponible',
        );
      }
    } catch (e) {
      encomiendaCreada = EncomiendaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uidRemitente: user.uid,
        nombreRemitente: nombreRemitente,
        origen: origen,
        destino: destino,
        descripcion: descripcion,
        peso: peso,
        valorPagar: valorPagar,
        fechaVencimiento: fechaVencimiento,
        estado: 'disponible',
      );
    }

    await _guardarEnSharedPublic(encomiendaCreada);
    return encomiendaCreada;
  }

  /// Obtener mis encomiendas creadas como remitente GET /api/encomiendas/mis-encomiendas
  Future<List<EncomiendaModel>> obtenerMisEncomiendas() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];

    try {
      final res = await _apiClient.get(ApiConstants.misEncomiendas);
      final rawList = _extraerLista(res);
      if (rawList.isNotEmpty) {
        return rawList.map((e) => EncomiendaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    final publicList = await _obtenerDeSharedPublic();
    return publicList.where((e) => e.uidRemitente == user.uid).toList();
  }

  /// Buscar encomiendas disponibles filtradas por la ruta del viajero (Origen -> Destino)
  Future<List<EncomiendaModel>> obtenerEncomiendasDisponibles({
    required String origen,
    required String destino,
  }) async {
    List<EncomiendaModel> resultado = [];

    try {
      final res = await _apiClient.get('${ApiConstants.encomiendasBuscar}?origen=$origen&destino=$destino');
      final rawList = _extraerLista(res);
      if (rawList.isNotEmpty) {
        resultado = rawList.map((e) => EncomiendaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      try {
        final resAll = await _apiClient.get(ApiConstants.encomiendasDisponibles);
        final rawList = _extraerLista(resAll);
        if (rawList.isNotEmpty) {
          resultado = rawList.map((e) => EncomiendaModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    final publicList = await _obtenerDeSharedPublic();
    for (var item in publicList) {
      if (!resultado.any((e) => e.id == item.id)) {
        resultado.add(item);
      }
    }

    return resultado;
  }

  /// Tomar / Aceptar encomienda PUT /api/encomiendas/tomar/{id}
  Future<bool> tomarEncomienda({
    required String id,
    required String viajeroNombre,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    try {
      await _apiClient.put(ApiConstants.tomarEncomienda(id), {
        'uidViajero': user.uid,
        'nombreViajero': viajeroNombre,
        'estado': 'tomada',
      });
    } catch (_) {}

    // Actualizar también en el almacenamiento compartido
    final publicList = await _obtenerDeSharedPublic();
    final index = publicList.indexWhere((e) => e.id == id);
    if (index != -1) {
      final actualizada = publicList[index].copyWith(
        estado: 'tomada',
        uidViajero: user.uid,
        nombreViajero: viajeroNombre,
      );
      await _guardarEnSharedPublic(actualizada);
    }
    return true;
  }

  /// Actualizar estado de encomienda PUT /api/encomiendas/{id}/estado
  Future<bool> actualizarEstado({
    required String id,
    required String nuevoEstado,
  }) async {
    try {
      await _apiClient.put(ApiConstants.encomiendaEstado(id), {
        'estado': nuevoEstado,
      });
    } catch (_) {}
    return true;
  }
}
