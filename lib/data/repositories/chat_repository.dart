import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../network/chat_firebase.dart';

/// Acceso a Firestore (proyecto "Lapticon Chat").
/// - chats/{idEncomienda}: chat entre remitente y viajero.
/// - encomiendas_canceladas/{idEncomienda}: encomiendas eliminadas por su
///   remitente; la app las oculta a TODOS los usuarios.
class ChatRepository {
  String get miUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<CollectionReference<Map<String, dynamic>>> _chats() async {
    final db = await ChatFirebase.db();
    return db.collection('chats');
  }

  Future<CollectionReference<Map<String, dynamic>>> _canceladas() async {
    final db = await ChatFirebase.db();
    return db.collection('encomiendas_canceladas');
  }

  // ---------------- Encomiendas canceladas ----------------

  /// Marca una encomienda como eliminada (visible para todos los usuarios).
  Future<void> marcarCancelada(String encomiendaId) async {
    final ref = (await _canceladas()).doc(encomiendaId);
    await ref.set({
      'uidRemitente': miUid,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  /// Ids de todas las encomiendas eliminadas.
  Future<Set<String>> obtenerCanceladas() async {
    final snap = await (await _canceladas()).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// true si un viajero ya aceptó esta encomienda (no se puede eliminar).
  Future<bool> tieneViajero(String chatId) async {
    final doc = await (await _chats()).doc(chatId).get();
    return (doc.data()?['uidViajero'] ?? '').toString().isNotEmpty;
  }

  // ---------------- Chat ----------------

  /// La REMITENTE registra su encomienda en Firestore.
  Future<void> registrarComoRemitente({
    required String chatId,
    required String nombreRemitente,
    String ruta = '',
  }) async {
    if (chatId.isEmpty || miUid.isEmpty) return;
    final ref = (await _chats()).doc(chatId);
    await ref.set({
      'encomiendaId': chatId,
      'uidRemitente': miUid,
      if (nombreRemitente.isNotEmpty && nombreRemitente != 'Remitente')
        'nombreRemitente': nombreRemitente,
      if (ruta.isNotEmpty) 'ruta': ruta,
      'participantes': FieldValue.arrayUnion([miUid]),
    }, SetOptions(merge: true));
  }

  /// El VIAJERO se agrega al chat cuando acepta la encomienda.
  Future<void> asegurarChat({
    required String chatId,
    required String uidRemitente,
    required String nombreRemitente,
    required String uidViajero,
    required String nombreViajero,
    String ruta = '',
  }) async {
    final ref = (await _chats()).doc(chatId);
    final participantes =
    [uidRemitente, uidViajero].where((u) => u.isNotEmpty).toList();
    await ref.set({
      'encomiendaId': chatId,
      if (uidRemitente.isNotEmpty) 'uidRemitente': uidRemitente,
      if (nombreRemitente.isNotEmpty && nombreRemitente != 'Remitente')
        'nombreRemitente': nombreRemitente,
      'uidViajero': uidViajero,
      'nombreViajero': nombreViajero,
      if (ruta.isNotEmpty) 'ruta': ruta,
      'participantes': FieldValue.arrayUnion(participantes),
      'matchVisto': false,
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mensajes de un chat en tiempo real, del más viejo al más nuevo.
  Stream<List<ChatMessageModel>> escucharMensajes(String chatId) async* {
    final col = await _chats();
    yield* col
        .doc(chatId)
        .collection('mensajes')
        .orderBy('timestamp')
        .snapshots()
        .map((s) =>
        s.docs.map((d) => ChatMessageModel.fromDoc(chatId, d)).toList());
  }

  /// Envía un mensaje y actualiza el resumen del chat en una sola operación.
  Future<void> enviarMensaje({
    required String chatId,
    required String texto,
    required String nombreRemitente,
  }) async {
    final chatRef = (await _chats()).doc(chatId);
    final msgRef = chatRef.collection('mensajes').doc();
    final batch = chatRef.firestore.batch();
    batch.set(msgRef, {
      'senderUid': miUid,
      'senderName': nombreRemitente,
      'text': texto,
      'timestamp': FieldValue.serverTimestamp(),
    });
    batch.set(chatRef, {
      'ultimoMensaje': texto,
      'ultimoSenderUid': miUid,
      'vistoPor': [miUid],
      'participantes': FieldValue.arrayUnion([miUid]),
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Chats donde participo y que ya tienen viajero (hubo match).
  Stream<List<ChatResumen>> escucharMisChats(String uid) async* {
    final col = await _chats();
    yield* col
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map((s) {
      final lista =
      s.docs.map(ChatResumen.fromDoc).where((c) => c.tieneViajero).toList();
      lista.sort((a, b) => b.actualizado.compareTo(a.actualizado));
      return lista;
    });
  }

  Future<void> marcarVisto(String chatId) async {
    final ref = (await _chats()).doc(chatId);
    await ref.set({
      'vistoPor': FieldValue.arrayUnion([miUid])
    }, SetOptions(merge: true));
  }

  Future<void> marcarMatchVisto(String chatId) async {
    final ref = (await _chats()).doc(chatId);
    await ref.set({'matchVisto': true}, SetOptions(merge: true));
  }
}
