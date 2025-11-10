import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../../core/utils/secure_storage_service.dart';
import '../models/chat_message.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ChatSocketService {
  final String? baseWsUrl; // ex: ws://localhost:8080/ws-chat
  final _storage = SecureStorageService();
  StompClient? _client;
  final _messageControllers = <String, StreamController<ChatMessage>>{};
  final _typingControllers = <String, StreamController<String>>{}; // senderName

  ChatSocketService({this.baseWsUrl});

  String _resolveWsUrl() {
    const path = '/ws-chat';
    const port = 8080;
    String host;
    if (baseWsUrl != null) return baseWsUrl!;
    if (kIsWeb) {
      host = 'localhost';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          host = '10.0.2.2';
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          host = 'localhost';
          break;
      }
    }
    return 'ws://$host:$port$path';
  }

  Future<void> connect() async {
    if (_client != null && _client!.connected) return;
    final token = await _storage.getToken();

    final base = _resolveWsUrl();
    final urlCandidates = <String>[
      base.endsWith('/websocket') ? base : '$base/websocket',
      base,
    ];

    Completer<void> connected = Completer<void>();
    _client = StompClient(
      config: StompConfig(
        url: urlCandidates.first,
        onConnect: (frame) {
          if (!connected.isCompleted) connected.complete();
        },
        beforeConnect: () async {
          // noop; could add backoff
        },
        onStompError: (StompFrame f) {
          if (!connected.isCompleted) connected.completeError(Exception('STOMP error: ${f.body}'));
        },
        onWebSocketError: (dynamic e) {
          if (!connected.isCompleted) connected.completeError(e);
        },
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        reconnectDelay: const Duration(milliseconds: 0),
      ),
    );
    _client!.activate();
    return connected.future;
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    // Do not close controllers to allow re-subscribe per room across pages
  }

  Stream<ChatMessage> subscribeRoomMessages(String roomId) {
    _messageControllers.putIfAbsent(roomId, () => StreamController.broadcast());
    _client?.subscribe(
      destination: '/topic/chat.room.$roomId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _messageControllers[roomId]!.add(ChatMessage.fromJson(data));
        }
      },
      headers: {'id': 'room-$roomId'},
    );
    return _messageControllers[roomId]!.stream;
  }

  Stream<String> subscribeTyping(String roomId) {
    _typingControllers.putIfAbsent(roomId, () => StreamController.broadcast());
    _client?.subscribe(
      destination: '/topic/chat.room.$roomId.typing',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          final sender = data['senderName']?.toString() ?? 'Usuário';
          _typingControllers[roomId]!.add(sender);
        }
      },
      headers: {'id': 'typing-$roomId'},
    );
    return _typingControllers[roomId]!.stream;
  }

  void sendMessage({required String roomId, required String content, String? clientMessageId}) {
    // Envia ambos campos para compatibilidade: chatRoomId e roomId
    final payload = <String, dynamic>{
      'chatRoomId': roomId,
      'roomId': roomId,
      'content': content,
    };
    if (clientMessageId != null) {
      payload['clientMessageId'] = clientMessageId;
    }
    _client?.send(
      destination: '/app/chat.send',
      body: jsonEncode(payload),
    );
  }

  Timer? _typingTimer;
  void sendTyping({required String roomId}) {
    _client?.send(
      destination: '/app/chat.typing',
      body: jsonEncode({'roomId': roomId}),
    );
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {});
  }
}
