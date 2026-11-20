import 'package:cloud_firestore/cloud_firestore.dart';

/// Un mensaje dentro de un chat (Firestore: chats/{chatId}/mensajes/{id}).
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessageModel.fromDoc(
      String chatId, DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['timestamp'];
    return ChatMessageModel(
      id: doc.id,
      chatId: chatId,
      senderUid: (d['senderUid'] ?? '').toString(),
      senderName: (d['senderName'] ?? '').toString(),
      text: (d['text'] ?? '').toString(),
      // Mientras el servidor asigna la hora, usamos la del celular.
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

/// Resumen de un chat (Firestore: chats/{chatId}). El chatId es el id de la encomienda.
class ChatResumen {
  final String chatId;
  final String uidRemitente;
  final String nombreRemitente;
  final String uidViajero;
  final String nombreViajero;
  final String ruta;
  final String ultimoMensaje;
  final String ultimoSenderUid;
  final List<String> vistoPor;
  final bool matchVisto;
  final DateTime actualizado;

  ChatResumen({
    required this.chatId,
    required this.uidRemitente,
    required this.nombreRemitente,
    required this.uidViajero,
    required this.nombreViajero,
    required this.ruta,
    required this.ultimoMensaje,
    required this.ultimoSenderUid,
    required this.vistoPor,
    required this.matchVisto,
    required this.actualizado,
  });

  bool get tieneViajero => uidViajero.isNotEmpty;
  bool soyRemitente(String uid) => uid == uidRemitente;

  /// Nombre de la otra persona del chat.
  String nombreDelOtro(String miUid) {
    final n = soyRemitente(miUid) ? nombreViajero : nombreRemitente;
    return n.isEmpty ? (soyRemitente(miUid) ? 'Viajero' : 'Remitente') : n;
  }

  /// true si el último mensaje es del otro y aún no lo he visto.
  bool tieneMensajeNuevo(String miUid) =>
      ultimoSenderUid.isNotEmpty &&
          ultimoSenderUid != miUid &&
          !vistoPor.contains(miUid);

  factory ChatResumen.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['actualizado'];
    return ChatResumen(
      chatId: doc.id,
      uidRemitente: (d['uidRemitente'] ?? '').toString(),
      nombreRemitente: (d['nombreRemitente'] ?? '').toString(),
      uidViajero: (d['uidViajero'] ?? '').toString(),
      nombreViajero: (d['nombreViajero'] ?? '').toString(),
      ruta: (d['ruta'] ?? '').toString(),
      ultimoMensaje: (d['ultimoMensaje'] ?? '').toString(),
      ultimoSenderUid: (d['ultimoSenderUid'] ?? '').toString(),
      vistoPor: List<String>.from(d['vistoPor'] ?? const []),
      matchVisto: d['matchVisto'] == true,
      actualizado: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
