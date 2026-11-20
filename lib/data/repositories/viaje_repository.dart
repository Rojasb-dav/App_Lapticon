import 'package:flutter/foundation.dart';
import '../../models/viaje_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

/// Acceso a los viajes en el backend (MongoDB en Render).
/// Los errores se lanzan (no se esconden) para que la pantalla muestre la razón real.
class ViajeRepository {
  final ApiClient _apiClient;
  ViajeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Formato de vuelo: 2 letras/números + 1 a 4 dígitos (ej. AV9340, AA916).
  static final _formatoVuelo = RegExp(r'^[A-Z0-9]{2}\d{1,4}$');

  /// Estados que se prueban para "cerrar" un viaje (no sabemos cuál acepta el backend).
  static const _estadosCierre = [
    'completado',
    'finalizado',
    'cerrado',
    'cancelado',
    'inactivo',
  ];

  /// GET /api/vuelos/:numero/:fecha (fecha AAAA-MM-DD).
  /// - 404: el vuelo no existe → se lanza el error (no se registra).
  /// - 500/502/503 o sin red: el servicio de vuelos no está disponible
  ///   (falta RAPIDAPI_KEY en Render) → se devuelve "Sin verificar".
  Future<VueloInfo> validarVuelo(String numero, String fecha) async {
    final n = numero.trim().toUpperCase().replaceAll(' ', '');
    if (!_formatoVuelo.hasMatch(n)) {
      throw ApiException('Formato de vuelo inválido. Ejemplo: AV9340', statusCode: 422);
    }
    try {
      final r = await _apiClient.get(
          ApiConstants.validarVuelo(Uri.encodeComponent(n), fecha));
      return VueloInfo.fromResponse(r);
    } on ApiException catch (e) {
      final code = e.statusCode ?? 0;
      if (code == 0 || code == 500 || code == 502 || code == 503) {
        debugPrint('Servicio de vuelos no disponible: $e');
        return VueloInfo(
          aerolinea: 'Sin verificar (servicio de vuelos no disponible)',
          origen: '',
          destino: '',
          salida: fecha,
        );
      }
      rethrow;
    }
  }

  /// POST /api/viajes con los nombres de campos que espera el backend.
  Future<void> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    await _apiClient.post(ApiConstants.viajes, {
      'numeroVuelo': numeroVuelo.trim().toUpperCase(),
      'fechaViaje': fecha,
      'ciudadOrigen': origen,
      'ciudadDestino': destino,
    });
  }

  /// GET /api/viajes → viajes del usuario autenticado.
  Future<List<ViajeModel>> misViajes() async {
    final r = await _apiClient.get(ApiConstants.viajes);
    dynamic lista = r;
    if (lista is Map) {
      lista = lista['data'] ?? lista['viajes'] ?? lista['result'] ?? lista['items'] ?? [];
    }
    if (lista is! List) return [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(ViajeModel.fromJson)
        .toList();
  }

  /// Cierra un viaje en el servidor para poder registrar otro.
  /// Prueba varias rutas posibles porque no conocemos la del backend:
  /// PUT/PATCH /api/viajes/:id/estado, PUT/PATCH /api/viajes/:id y DELETE /api/viajes/:id.
  /// Si ninguna existe, lanza un error 404.
  Future<void> cerrarViaje(String id) async {
    final rutas = <String, Future<dynamic> Function(Map<String, dynamic>)>{
      'PUT estado': (b) => _apiClient.put(ApiConstants.viajeEstado(id), b),
      'PATCH estado': (b) => _apiClient.patch(ApiConstants.viajeEstado(id), b),
      'PUT viaje': (b) => _apiClient.put('${ApiConstants.viajes}/$id', b),
      'PATCH viaje': (b) => _apiClient.patch('${ApiConstants.viajes}/$id', b),
    };

    for (final ruta in rutas.entries) {
      for (final estado in _estadosCierre) {
        try {
          await ruta.value({'estado': estado});
          debugPrint('✅ Viaje cerrado con ${ruta.key} y estado "$estado"');
          return;
        } on ApiException catch (e) {
          // 400/422: la ruta existe pero no acepta ese estado → probar el siguiente.
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          // 404/405/otro: esta ruta no existe → probar la siguiente ruta.
          break;
        }
      }
    }

    try {
      await _apiClient.delete('${ApiConstants.viajes}/$id');
      debugPrint('✅ Viaje eliminado con DELETE');
      return;
    } on ApiException catch (e) {
      debugPrint('DELETE tampoco funcionó: $e');
    }

    throw ApiException('El servidor no tiene una ruta para cerrar viajes.',
        statusCode: 404);
  }
}
