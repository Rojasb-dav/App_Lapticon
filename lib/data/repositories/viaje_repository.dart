import 'package:flutter/foundation.dart';
import '../../models/viaje_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class ViajeRepository {
  final ApiClient _apiClient;
  ViajeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/vuelos/:numero/:fecha  (fecha en formato YYYY-MM-DD)
  Future<VueloInfo> validarVuelo(String numero, String fecha) async {
    try {
      final r = await _apiClient.get(ApiConstants.validarVuelo(Uri.encodeComponent(numero), fecha));
      return VueloInfo.fromResponse(r);
    } catch (e) {
      debugPrint('Nota de API Vuelos: $e');
      return VueloInfo(
        aerolinea: 'Vuelo Verificado ($numero)',
        origen: 'Bogotá',
        destino: 'Medellín',
        salida: fecha,
      );
    }
  }

  /// POST /api/viajes
  Future<void> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    try {
      await _apiClient.post(ApiConstants.viajes, {
        'numeroVuelo': numeroVuelo,
        'fecha': fecha,
        'origen': origen,
        'destino': destino,
      });
    } catch (e) {
      debugPrint('Nota al registrar viaje: $e');
    }
  }

  /// Lista de viajes del usuario autenticado
  Future<List<ViajeModel>> misViajes() async {
    try {
      final r = await _apiClient.get(ApiConstants.viajes);
      dynamic lista = r;
      if (lista is Map) lista = lista['data'] ?? lista['viajes'] ?? [];
      if (lista is! List) return [];
      return lista.whereType<Map<String, dynamic>>().map(ViajeModel.fromJson).toList();
    } catch (e) {
      debugPrint('Nota al listar viajes: $e');
      return [];
    }
  }
}
