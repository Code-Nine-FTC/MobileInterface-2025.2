import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

class ChatApiDataSource {
  final BaseApiService _api = BaseApiService();

  Future<List<ChatRoom>> getAllRooms() async {
    final Response resp = await _api.get('/api/chat/rooms');
    final list = resp.data as List<dynamic>;
    return list.map((e) => ChatRoom.fromJson(e)).toList();
  }

  Future<List<ChatRoom>> getActiveRooms() async {
    final Response resp = await _api.get('/api/chat/rooms/active');
    final list = resp.data as List<dynamic>;
    return list.map((e) => ChatRoom.fromJson(e)).toList();
  }

  Future<ChatRoom> createRoom({required String name, required List<String> participantIds}) async {
    final Response resp = await _api.post('/api/chat/rooms', data: {
      'name': name,
      'participants': participantIds,
    });
    return ChatRoom.fromJson(resp.data);
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    final Response resp = await _api.get('/api/chat/rooms/$roomId/messages');
    final list = resp.data as List<dynamic>;
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> markMessagesRead(String roomId) async {
    await _api.put('/api/chat/rooms/$roomId/messages/read');
  }

  Future<void> closeRoom(String roomId) async {
    await _api.put('/api/chat/rooms/$roomId/close');
  }

  // Tenta deletar permanentemente a sala (se backend suportar endpoint REST DELETE)
  Future<void> deleteRoom(String roomId) async {
    await _api.delete('/api/chat/rooms/$roomId');
  }

  Future<void> reopenRoom(String roomId) async {
    await _api.put('/api/chat/rooms/$roomId/reopen');
  }

  Future<ChatRoom> getDirectRoom(String userId) async {
    final Response resp = await _api.get('/api/chat/direct/$userId');
    return ChatRoom.fromJson(resp.data);
  }

  // Convida um cliente por e-mail e cria/retorna a sala correspondente
  Future<ChatRoom> inviteGuestByEmail(String email) async {
    try {
      // Backend espera 'guestEmail' (conforme logs/DTO). Enviamos no campo correto.
      final Response resp = await _api.post('/api/chat/invite', data: {
        'guestEmail': email,
      });
      return ChatRoom.fromJson(resp.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('E-mail inválido ou já convidado.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado: verifique suas permissões.');
      }
      rethrow;
    }
  }
}
