import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../network/chat_firebase.dart';

/// Acceso al chat en Firestore (proyecto "Lapticon Chat").
/// El uid usado es el de la cuenta real de la app (Firebase de David),
/// no el anónimo del proyecto de chat.
class ChatRepository {
  String get miUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<CollectionReference<Map<String, dynamic>>> _chats() async {
    final db = await ChatFirebase.db();
    return db.collection('chats');
  }

  /// Crea (o completa) el chat cuando un viajero acepta una encomienda.
  /// Así el remitente lo ve y recibe el aviso de "¡Hiciste match!".
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
      'uidRemitente': uidRemitente,
      'nombreRemitente': nombreRemitente,
      'uidViajero': uidViajero,
      'nombreViajero': nombreViajero,
      'ruta': ruta,
      'participantes': FieldValue.arrayUnion(participantes),
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
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Todos los chats donde participo (remitente o viajero), en tiempo real.
  Stream<List<ChatResumen>> escucharMisChats(String uid) async* {
    final col = await _chats();
    yield* col
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(ChatResumen.fromDoc).toList();
      // Se ordena aquí para no necesitar índices en Firestore.
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
