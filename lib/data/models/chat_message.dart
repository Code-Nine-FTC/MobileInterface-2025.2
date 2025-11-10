class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool read;
  final String? clientMessageId; // identificador gerado pelo cliente para dedupe

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.read,
    this.clientMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Extrai possíveis formatos de sender
    String senderId = json['senderId']?.toString() ?? json['sender']?.toString() ?? '';
    String senderName = json['senderName']?.toString() ?? 'Usuário';
    final senderObj = json['sender'];
    if (senderObj is Map<String, dynamic>) {
      senderId = senderObj['id']?.toString() ?? senderId;
      senderName = senderObj['name']?.toString() ?? senderObj['fullName']?.toString() ?? senderName;
    }

    // Conteúdo pode vir em várias chaves
    final content = json['content']?.toString() ??
        json['text']?.toString() ??
        json['message']?.toString() ??
        json['body']?.toString() ?? '';

    // Timestamp com chaves alternativas
    final tsRaw = json['timestamp']?.toString() ??
        json['createdAt']?.toString() ??
        json['sentAt']?.toString() ??
        json['date']?.toString() ??
        json['createdDate']?.toString() ??
        json['time']?.toString() ?? '';
    final ts = DateTime.tryParse(tsRaw) ?? DateTime.now();

    // Flag de leitura alternativa
    final isRead = json['read'] == true || json['seen'] == true || json['status']?.toString() == 'READ';

    return ChatMessage(
      id: json['id'].toString(),
      // compat: aceita 'chatRoomId', 'roomId' ou 'room'
      roomId: json['chatRoomId']?.toString() ?? json['roomId']?.toString() ?? json['room']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: ts,
      read: isRead,
      clientMessageId: json['clientMessageId']?.toString(),
    );
  }
}
