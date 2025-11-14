import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/api/chat_api_data_source.dart';
import '../../../data/socket/chat_socket_service.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/secure_storage_service.dart';

/// Página de chat exclusiva para usuários GUEST
/// Mostra apenas o chat associado ao guest, sem menu ou outras funcionalidades
class GuestChatPage extends StatefulWidget {
  final String? roomId;
  final String? roomName;

  const GuestChatPage({
    super.key,
    this.roomId,
    this.roomName,
  });

  @override
  State<GuestChatPage> createState() => _GuestChatPageState();
}

class _GuestChatPageState extends State<GuestChatPage> {
  final _api = ChatApiDataSource();
  final _socket = ChatSocketService();
  final _storage = SecureStorageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;
  String? _currentUserName;
  String? _actualRoomId;
  String? _actualRoomName;
  StreamSubscription<ChatMessage>? _messageSub;
  bool _socketConnected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _storage.getUser();
      _currentUserId = user?.id.toString();
      _currentUserName = user?.name ?? 'Você';
      
      // Tentar pegar roomId dos argumentos, senão do storage
      String? roomId = widget.roomId;
      if (roomId == null || roomId.isEmpty) {
        roomId = await _storage.getChatRoomId();
        print('[GuestChat] RoomId obtido do storage: $roomId');
      } else {
        print('[GuestChat] RoomId obtido dos argumentos: $roomId');
      }
      
      setState(() {
        _actualRoomId = roomId;
        _actualRoomName = widget.roomName ?? 'Chat';
      });

      if (_actualRoomId != null && _actualRoomId!.isNotEmpty) {
        print('[GuestChat] Carregando mensagens do room: $_actualRoomId');
        await _loadMessages();
        await _connectSocket();
      } else {
        setState(() {
          _error = 'Sala de chat não encontrada';
          _loading = false;
        });
        print('[GuestChat] ERRO - Sala de chat não encontrada');
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar chat: $e';
        _loading = false;
      });
      print('[GuestChat] ERRO ao inicializar: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('[GuestChat] Chamando API para carregar mensagens - RoomId: $_actualRoomId');
      final msgs = await _api.getMessages(_actualRoomId!);
      print('[GuestChat] Mensagens carregadas: ${msgs.length}');
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
      await _api.markMessagesRead(_actualRoomId!);
    } catch (e) {
      print('[GuestChat] ERRO ao carregar mensagens: $e');
      setState(() {
        _error = 'Erro ao carregar mensagens: $e';
        _loading = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    try {
      print('[GuestChat] Tentando conectar ao socket...');
      await _socket.connect();
      print('[GuestChat] Socket conectado! Subscrevendo ao room: $_actualRoomId');
      
      setState(() {
        _socketConnected = true;
      });
      
      _messageSub = _socket.subscribeRoomMessages(_actualRoomId!).listen((msg) {
        print('[GuestChat] Nova mensagem recebida via socket: ${msg.content}');
        if (msg.roomId == _actualRoomId) {
          setState(() {
            // Remove mensagem otimista se existir
            _messages.removeWhere((m) => 
              m.senderId == _currentUserId && 
              m.content == msg.content &&
              m.id.startsWith('temp_')
            );
            // Adiciona mensagem real
            _messages.add(msg);
          });
          _scrollToBottom();
          if (msg.senderId != _currentUserId) {
            _api.markMessagesRead(_actualRoomId!);
          }
        }
      });
      print('[GuestChat] Subscrição ao room configurada');
    } catch (e) {
      print('[GuestChat] ERRO ao conectar socket: $e');
      setState(() {
        _socketConnected = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _actualRoomId == null) {
      print('[GuestChat] Mensagem vazia ou roomId null');
      return;
    }

    print('[GuestChat] Enviando mensagem - RoomId: $_actualRoomId, Texto: $text');
    
    // Limpa o campo imediatamente para feedback visual
    _messageController.clear();
    
    // Adiciona mensagem otimista na UI
    final optimisticMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      roomId: _actualRoomId!,
      senderId: _currentUserId ?? 'me',
      senderName: _currentUserName ?? 'Você',
      content: text,
      timestamp: DateTime.now(),
      read: true,
    );
    
    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();
    
    try {
      _socket.sendMessage(roomId: _actualRoomId!, content: text);
      print('[GuestChat] Mensagem enviada via socket');
    } catch (e) {
      print('[GuestChat] ERRO ao enviar mensagem: $e');
      
      // Remove mensagem otimista em caso de erro
      setState(() {
        _messages.removeWhere((m) => m.id == optimisticMessage.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _storage.deleteToken();
      _socket.disconnect();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _socket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_actualRoomName ?? 'Chat'),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _socketConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Mensagens
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadMessages,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhuma mensagem ainda.\nInicie a conversa!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) => _buildMessage(_messages[i]),
                            ),
            ),

            // Campo de envio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.infoLight],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isMe = msg.senderId == _currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [AppColors.primaryLight, AppColors.infoLight])
              : null,
          color: isMe ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                msg.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}
