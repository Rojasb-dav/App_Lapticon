import 'package:firebase_auth/firebase_auth.dart';
import '../../models/encomienda_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

/// Encomiendas guardadas en el backend: así las ven otros usuarios
/// y se conservan al cambiar de celular. Los errores se lanzan (no se ocultan).
class EncomiendaRepository {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;

  EncomiendaRepository({ApiClient? apiClient, FirebaseAuth? firebaseAuth})
      : _apiClient = apiClient ?? ApiClient(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Estados que se prueban para cancelar una encomienda en el servidor.
  static const _estadosCancelacion = ['cancelada', 'cancelado', 'eliminada'];

  /// El backend responde a veces una lista directa y otras un objeto
  /// con listas adentro (ej. {"disponibles": [...]}). Se juntan todas.
  List<EncomiendaModel> _extraerLista(dynamic res) {
    final mapas = <Map<String, dynamic>>[];
    if (res is List) {
      mapas.addAll(res.whereType<Map<String, dynamic>>());
    } else if (res is Map) {
      for (final v in res.values) {
        if (v is List) mapas.addAll(v.whereType<Map<String, dynamic>>());
      }
    }
    return mapas.map(EncomiendaModel.fromJson).toList();
  }

  /// POST /api/encomiendas (nombres confirmados en Postman: 201 Created)
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

    final res = await _apiClient.post(ApiConstants.encomiendas, {
      'ciudadOrigen': origen,
      'ciudadDestino': destino,
      'valor': valorPagar,
      'observaciones': '$descripcion (Peso: $peso)',
      'fechaLimiteEntrega': fechaVencimiento,
      'nombreRemitente': nombreRemitente,
    });

    dynamic data = res;
    if (data is Map && data['encomienda'] is Map) data = data['encomienda'];
    if (data is Map && data['data'] is Map) data = data['data'];
    if (data is Map<String, dynamic>) return EncomiendaModel.fromJson(data);

    // Se guardó, pero el backend no devolvió el objeto: se recarga luego.
    return EncomiendaModel(
      id: '', uidRemitente: user.uid, nombreRemitente: nombreRemitente,
      origen: origen, destino: destino, descripcion: descripcion, peso: peso,
      valorPagar: valorPagar, fechaVencimiento: fechaVencimiento, estado: 'disponible',
    );
  }

  /// GET /api/encomiendas/mis-encomiendas
  Future<List<EncomiendaModel>> obtenerMisEncomiendas() async {
    final res = await _apiClient.get(ApiConstants.misEncomiendas);
    return _extraerLista(res);
  }

  /// GET /api/encomiendas/disponibles?origen=...&destino=...
  Future<List<EncomiendaModel>> obtenerEncomiendasDisponibles({
    required String origen,
    required String destino,
  }) async {
    final o = Uri.encodeQueryComponent(origen);
    final d = Uri.encodeQueryComponent(destino);
    final res = await _apiClient
        .get('${ApiConstants.encomiendasDisponibles}?origen=$o&destino=$d');
    return _extraerLista(res);
  }

  /// PUT /api/encomiendas/tomar/:id → el viajero acepta la encomienda (el match).
  Future<bool> tomarEncomienda({
    required String id,
    required String viajeroNombre,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No hay sesión de usuario activa.');
    await _apiClient.put(ApiConstants.tomarEncomienda(id), {
      'nombreViajero': viajeroNombre,
      'uidViajero': user.uid,
    });
    return true;
  }

  /// PUT /api/encomiendas/:id/estado
  Future<bool> actualizarEstado({
    required String id,
    required String nuevoEstado,
  }) async {
    await _apiClient.put(ApiConstants.encomiendaEstado(id), {'estado': nuevoEstado});
    return true;
  }

  /// Intenta eliminar/cancelar la encomienda EN EL SERVIDOR.
  /// Prueba: DELETE /api/encomiendas/:id, luego PUT y PATCH /api/encomiendas/:id/estado.
  /// Si ninguna ruta existe, lanza un error 404 (la app la cancela en Firestore).
  Future<void> eliminarEncomienda(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.encomiendas}/$id');
      return;
    } on ApiException catch (_) {
      // No existe DELETE → probar cambiar el estado.
    }

    for (final metodo in ['PUT', 'PATCH']) {
      for (final estado in _estadosCancelacion) {
        try {
          final body = {'estado': estado};
          if (metodo == 'PUT') {
            await _apiClient.put(ApiConstants.encomiendaEstado(id), body);
          } else {
            await _apiClient.patch(ApiConstants.encomiendaEstado(id), body);
          }
          return;
        } on ApiException catch (e) {
          // 400/422: la ruta existe pero no acepta ese estado → probar otro.
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          break; // la ruta no existe → probar el siguiente método
        }
      }
    }

    throw ApiException('El servidor no tiene una ruta para eliminar encomiendas.',
        statusCode: 404);
  }
}
