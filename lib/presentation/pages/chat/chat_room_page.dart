import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/api/chat_api_data_source.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/socket/chat_socket_service.dart';
import '../../../core/utils/secure_storage_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  const ChatRoomPage({super.key, required this.roomId, required this.roomName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _api = ChatApiDataSource();
  final _socket = ChatSocketService();
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _listController = ScrollController();
  String? _myUserId;
  String? _myUserName;
  StreamSubscription<ChatMessage>? _subMsg;
  StreamSubscription<String>? _subTyping;
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    _initUser().then((_) {
      _load();
      _initSocket();
    });
  }

  Future<void> _initUser() async {
    final storage = SecureStorageService();
    final user = await storage.getUser();
    setState(() {
      _myUserId = user?.id.toString();
      _myUserName = user?.name ?? 'Você';
    });
  }

  Future<void> _load() async {
    final history = await _api.getMessages(widget.roomId);
    setState(() {
      _messages
        ..clear()
        ..addAll(history);
    });
    // marca como lidas
    unawaited(_api.markMessagesRead(widget.roomId));
    _scrollToBottom();
  }

  Future<void> _initSocket() async {
    await _socket.connect();
    _subMsg = _socket.subscribeRoomMessages(widget.roomId).listen((m) {
      setState(() {
        _messages.add(m);
      });
      _scrollToBottom();
    });
    _subTyping = _socket.subscribeTyping(widget.roomId).listen((u) {
      setState(() {
        _typingUser = u;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _typingUser = null);
      });
    });
  }

  @override
  void dispose() {
    _subMsg?.cancel();
    _subTyping?.cancel();
    _controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Otimismo: adiciona localmente
    final local = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      roomId: widget.roomId, // manter compat com parser
      senderId: _myUserId ?? 'me',
      senderName: _myUserName ?? 'Você',
      content: text,
      timestamp: DateTime.now(),
      read: true,
    );
    setState(() {
      _messages.add(local);
    });
    _scrollToBottom();
    _socket.sendMessage(roomId: widget.roomId, content: text);
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            if (_typingUser != null)
              Text('${_typingUser!} está digitando...', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _listController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMine = _myUserId != null && m.senderId == _myUserId;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue.shade200 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMine ? 'Você' : m.senderName,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(m.content),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (_) => _socket.sendTyping(roomId: widget.roomId),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
