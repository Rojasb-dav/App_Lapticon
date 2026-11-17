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

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderUid: (json['senderUid'] ?? json['uid'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['nombre'] ?? 'Usuario').toString(),
      text: (json['text'] ?? json['mensaje'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
