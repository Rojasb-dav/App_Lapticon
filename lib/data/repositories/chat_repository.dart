import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';

class ChatRepository {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;

  final Map<String, List<ChatMessageModel>> _localChatStore = {};

  ChatRepository({ApiClient? apiClient, FirebaseAuth? firebaseAuth})
      : _apiClient = apiClient ?? ApiClient(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Obtener historial de mensajes de un chat
  Future<List<ChatMessageModel>> obtenerMensajes(String chatId) async {
    try {
      final res = await _apiClient.get(ApiConstants.chatEstado(chatId));
      if (res is Map<String, dynamic> && res.containsKey('mensajes') && res['mensajes'] is List) {
        final list = (res['mensajes'] as List)
            .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
            .toList();
        _localChatStore[chatId] = list;
        return list;
      }
    } catch (_) {}

    return _localChatStore[chatId] ?? [];
  }

  /// Enviar mensaje en el chat
  Future<ChatMessageModel> enviarMensaje({
    required String chatId,
    required String texto,
    required String nombreRemitente,
  }) async {
    final user = _firebaseAuth.currentUser;
    final uid = user?.uid ?? 'anonimo';

    final nuevoMensaje = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderUid: uid,
      senderName: nombreRemitente,
      text: texto,
      timestamp: DateTime.now(),
    );

    if (!_localChatStore.containsKey(chatId)) {
      _localChatStore[chatId] = [];
    }
    _localChatStore[chatId]!.add(nuevoMensaje);

    try {
      await _apiClient.post('/api/chats/$chatId/mensaje', nuevoMensaje.toJson());
    } catch (_) {}

    return nuevoMensaje;
  }
}
