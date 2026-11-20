import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/chat_repository.dart';
import '../models/chat_model.dart';

/// Estado del chat: mensajes del chat abierto y lista de "Mis chats".
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo;
  ChatViewModel({ChatRepository? chatRepository})
      : _repo = chatRepository ?? ChatRepository();

  List<ChatMessageModel> _mensajes = [];
  List<ChatResumen> _misChats = [];
  bool _isLoading = false;
  String? _error;
  String? _uidEscuchando;
  StreamSubscription<List<ChatMessageModel>>? _subMensajes;
  StreamSubscription<List<ChatResumen>>? _subChats;

  List<ChatMessageModel> get mensajes => _mensajes;
  List<ChatResumen> get misChats => _misChats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get miUid => _repo.miUid;

  /// Matches que el remitente todavía no ha visto (para el aviso verde).
  List<ChatResumen> get matchesNuevos => _misChats
      .where((c) => c.soyRemitente(miUid) && c.tieneViajero && !c.matchVisto)
      .toList();

  /// Número del globito rojo sobre el ícono 💬.
  int get pendientes => _misChats
      .where((c) =>
  (c.soyRemitente(miUid) && c.tieneViajero && !c.matchVisto) ||
      c.tieneMensajeNuevo(miUid))
      .length;

  String _limpiar(Object e) => e.toString().replaceAll('Exception: ', '');

  /// Empieza a escuchar mis chats (se llama desde HomeScreen).
  void escucharMisChats() {
    final uid = miUid;
    if (uid.isEmpty || uid == _uidEscuchando) return;
    _uidEscuchando = uid;
    _subChats?.cancel();
    _subChats = _repo.escucharMisChats(uid).listen((lista) {
      _misChats = lista;
      notifyListeners();
    }, onError: (e) {
      _error = 'No se pudieron cargar tus chats: ${_limpiar(e)}';
      notifyListeners();
    });
  }

  /// Abre un chat y escucha sus mensajes en tiempo real.
  void abrirChat(String chatId) {
    _subMensajes?.cancel();
    _mensajes = [];
    _error = null;
    _isLoading = true;
    notifyListeners();
    _subMensajes = _repo.escucharMensajes(chatId).listen((lista) {
      _mensajes = lista;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      _error = 'No se pudo conectar al chat: ${_limpiar(e)}';
      notifyListeners();
    });
    _repo.marcarVisto(chatId).catchError((_) {});
  }

  /// Compatibilidad con el código anterior.
  Future<void> cargarMensajes(String chatId) async => abrirChat(chatId);

  /// Deja de escuchar el chat abierto (sin notificar: se llama en dispose).
  void cerrarChat() {
    _subMensajes?.cancel();
    _subMensajes = null;
  }

  /// Devuelve null si se envió bien, o el mensaje de error.
  Future<String?> enviarMensaje({
    required String chatId,
    required String texto,
    required String nombreRemitente,
  }) async {
    if (texto.trim().isEmpty) return null;
    try {
      await _repo.enviarMensaje(
          chatId: chatId, texto: texto.trim(), nombreRemitente: nombreRemitente);
      return null;
    } catch (e) {
      return 'No se pudo enviar: ${_limpiar(e)}';
    }
  }

  /// Registra el match en Firestore (lo llama el viajero al aceptar).
  Future<String?> asegurarChat({
    required String chatId,
    required String uidRemitente,
    required String nombreRemitente,
    required String nombreViajero,
    String ruta = '',
  }) async {
    try {
      await _repo.asegurarChat(
        chatId: chatId,
        uidRemitente: uidRemitente,
        nombreRemitente: nombreRemitente,
        uidViajero: miUid,
        nombreViajero: nombreViajero,
        ruta: ruta,
      );
      return null;
    } catch (e) {
      return _limpiar(e);
    }
  }

  Future<void> marcarMatchVisto(String chatId) async {
    try {
      await _repo.marcarMatchVisto(chatId);
    } catch (_) {}
  }

  /// Llamar al cerrar sesión.
  void detener() {
    _subChats?.cancel();
    _subMensajes?.cancel();
    _uidEscuchando = null;
    _misChats = [];
    _mensajes = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subChats?.cancel();
    _subMensajes?.cancel();
    super.dispose();
  }
}
