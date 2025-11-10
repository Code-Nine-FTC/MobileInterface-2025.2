import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/api/chat_api_data_source.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/socket/chat_socket_service.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../components/standartScreen.dart';

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
  final Set<String> _recentSentKeys = <String>{};
  final Map<String, int> _pendingByClientId = {}; // clientMessageId -> index na lista
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
      final isMine = _myUserId != null && m.senderId == _myUserId;
      if (isMine && m.clientMessageId != null && _pendingByClientId.containsKey(m.clientMessageId!)) {
        // Eco do servidor para uma mensagem otimista: substitui a versão local
        final idx = _pendingByClientId.remove(m.clientMessageId!)!;
        setState(() {
          _messages[idx] = m; // mantém posição, atualiza id/timestamp definitivos
        });
        _scrollToBottom();
        return;
      }
      final key = '${m.roomId}|${m.senderId}|${m.content}';
      if (isMine && _recentSentKeys.contains(key)) {
        // fallback dedupe quando backend não devolve clientMessageId
        _recentSentKeys.remove(key);
        return;
      }
      setState(() => _messages.add(m));
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
    final clientMessageId = 'local_${_myUserId}_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: clientMessageId, // id provisório
      roomId: widget.roomId,
      senderId: _myUserId ?? 'me',
      senderName: _myUserName ?? 'Você',
      content: text,
      timestamp: DateTime.now(),
      read: true,
      clientMessageId: clientMessageId,
    );
    setState(() {
      _messages.add(optimistic);
      _pendingByClientId[clientMessageId] = _messages.length - 1;
    });
    // chave de dedupe tradicional como fallback caso backend ignore clientMessageId
    final key = '${widget.roomId}|${_myUserId}|$text';
    _recentSentKeys.add(key);
    Future.delayed(const Duration(seconds: 5), () => _recentSentKeys.remove(key));

    _socket.sendMessage(roomId: widget.roomId, content: text, clientMessageId: clientMessageId);
    _controller.clear();
    _scrollToBottom();
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
    final bubbles = ListView.builder(
      controller: _listController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        final isMine = _myUserId != null && m.senderId == _myUserId;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) _avatar(m.senderName),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMine
                        ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
                        : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMine)
                        Text(
                          m.senderName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      if (!isMine) const SizedBox(height: 2),
                      Text(
                        m.content,
                        style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatTime(m.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMine ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 4),
            ],
          ),
        );
      },
    );

    final inputBar = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Mensagem...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => _socket.sendTyping(roomId: widget.roomId),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blue.shade600,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _send,
              ),
            )
          ],
        ),
      ),
    );

    return StandardScreen(
      title: widget.roomName,
      showBackButton: true,
      actions: [
        if (_typingUser != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${_typingUser!} digitando...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: 'Excluir / Encerrar',
          onPressed: _confirmDeleteRoom,
        ),
      ],
      child: Column(
        children: [
          Expanded(child: bubbles),
          inputBar,
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _avatar(String name) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p.substring(0, 1)).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 2),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _confirmDeleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conversa'),
        content: const Text('Deseja realmente excluir ou encerrar esta conversa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      // Tenta deletar primeiro; se falhar (ex: 404 ou 405), faz close
      final api = ChatApiDataSource();
      bool deleted = false;
      try {
        await api.deleteRoom(widget.roomId);
        deleted = true;
      } catch (_) {
        await api.closeRoom(widget.roomId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(deleted ? 'Conversa excluída.' : 'Conversa encerrada.')),
      );
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
      );
    }
  }
}
