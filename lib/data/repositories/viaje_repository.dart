import '../../models/viaje_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class ViajeRepository {
  final ApiClient _apiClient;
  ViajeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/vuelos/:numero/:fecha  (fecha en formato YYYY-MM-DD)
  Future<VueloInfo> validarVuelo(String numero, String fecha) async {
    final r = await _apiClient.get(ApiConstants.validarVuelo(Uri.encodeComponent(numero), fecha));
    return VueloInfo.fromResponse(r);
  }

  /// POST /api/viajes
  Future<void> registrarViaje({
    required String numeroVuelo,
    required String fecha,
    required String origen,
    required String destino,
  }) async {
    await _apiClient.post(ApiConstants.viajes, {
      'numeroVuelo': numeroVuelo, // ⚠ verificar nombres en Apiary
      'fecha': fecha,
      'origen': origen,
      'destino': destino,
    });
  }

  /// Lista de viajes del usuario autenticado
  Future<List<ViajeModel>> misViajes() async {
    final r = await _apiClient.get(ApiConstants.misViajes);
    dynamic lista = r;
    if (lista is Map) lista = lista['data'] ?? lista['viajes'] ?? [];
    if (lista is! List) return [];
    return lista.whereType<Map<String, dynamic>>().map(ViajeModel.fromJson).toList();
  }
}
