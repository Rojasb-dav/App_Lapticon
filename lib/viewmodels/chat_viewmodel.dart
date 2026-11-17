import 'package:flutter/foundation.dart';
import '../data/repositories/chat_repository.dart';
import '../models/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;

  List<ChatMessageModel> _mensajes = [];
  bool _isLoading = false;

  ChatViewModel({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? ChatRepository();

  List<ChatMessageModel> get mensajes => _mensajes;
  bool get isLoading => _isLoading;

  /// Cargar historial de chat
  Future<void> cargarMensajes(String chatId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _mensajes = await _chatRepository.obtenerMensajes(chatId);
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enviar mensaje
  Future<void> enviarMensaje({
    required String chatId,
    required String texto,
    required String nombreRemitente,
  }) async {
    if (texto.trim().isEmpty) return;

    final msg = await _chatRepository.enviarMensaje(
      chatId: chatId,
      texto: texto.trim(),
      nombreRemitente: nombreRemitente,
    );

    if (!_mensajes.any((m) => m.id == msg.id)) {
      _mensajes.add(msg);
      notifyListeners();
    }
  }
}
