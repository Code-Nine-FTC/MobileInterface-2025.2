class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      // compat: aceita 'chatRoomId', 'roomId' ou 'room'
      roomId: json['chatRoomId']?.toString() ?? json['roomId']?.toString() ?? json['room']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Usuário',
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      read: json['read'] == true,
    );
  }
}
