import 'chat_message.dart';
import 'package:mobile_interface_2025_2/domain/entities/user.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<User> participants;
  final ChatMessage? lastMessage;
  final bool active;
  final DateTime? updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.active,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    ChatMessage? last;
    // Backend pode enviar objeto completo em 'lastMessage'
    if (json['lastMessage'] != null) {
      last = ChatMessage.fromJson(json['lastMessage']);
    } else if (json['lastMessageContent'] != null) {
      // Fallback: apenas conteúdo + possivelmente timestamp/
      last = ChatMessage(
        id: 'last-${json['id']}',
        roomId: json['id'].toString(),
        senderId: json['lastMessageSenderId']?.toString() ?? '',
        senderName: json['lastMessageSenderName']?.toString() ?? 'Usuário',
        content: json['lastMessageContent'].toString(),
        timestamp: DateTime.tryParse(json['lastMessageTimestamp']?.toString() ?? '') ?? DateTime.now(),
        read: true,
        isFromCurrentUser: false, // preview sem contexto
      );
    } else if (json['latestMessage'] != null) {
      // Alternativa: alguns backends usam 'latestMessage'
      final lm = json['latestMessage'];
      if (lm is Map<String, dynamic>) {
        last = ChatMessage.fromJson(lm);
      } else if (lm is String && lm.trim().isNotEmpty) {
        last = ChatMessage(
          id: 'last-${json['id']}',
          roomId: json['id'].toString(),
          senderId: '',
          senderName: 'Mensagem',
          content: lm,
          timestamp: DateTime.now(),
          read: true,
          isFromCurrentUser: false, // preview sem contexto
        );
      }
    } else if (json['lastMessageText'] != null) {
      last = ChatMessage(
        id: 'last-${json['id']}',
        roomId: json['id'].toString(),
        senderId: json['lastMessageUserId']?.toString() ?? '',
        senderName: json['lastMessageUserName']?.toString() ?? 'Usuário',
        content: json['lastMessageText'].toString(),
        timestamp: DateTime.tryParse(json['lastMessageDate']?.toString() ?? '') ?? DateTime.now(),
        read: true,
        isFromCurrentUser: false, // preview sem contexto
      );
    }
    return ChatRoom(
      id: json['id'].toString(),
      name: json['name'] ?? 'Sem nome',
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: last,
      active: json['active'] == null ? true : json['active'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
