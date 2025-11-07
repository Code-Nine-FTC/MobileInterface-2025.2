import 'package:flutter/material.dart';
import '../../../data/api/chat_api_data_source.dart';
import '../../../data/models/chat_room.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/secure_storage_service.dart';

class ChatRoomsPage extends StatefulWidget {
  const ChatRoomsPage({super.key});

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  final _api = ChatApiDataSource();
  bool _onlyActive = false;
  Future<List<ChatRoom>>? _future;
  bool _canInvite = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Define se o usuário pode convidar (ADMIN ou Farmácia sessão 2)
    final storage = SecureStorageService();
    final user = await storage.getUser();
    setState(() {
      _canInvite = (user?.role == 'ADMIN') || (user?.sessionId == '2');
    });
    _load();
  }

  void _load() {
    setState(() {
      _future = _onlyActive ? _api.getActiveRooms() : _api.getAllRooms();
    });
  }

  Future<void> _showInviteDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateSB) {
          String? validator(String? v) {
            final email = (v ?? '').trim();
            if (email.isEmpty) return 'Informe o e-mail do cliente';
            if (!email.contains('@') || !email.contains('.')) return 'E-mail inválido';
            return null;
          }
          return AlertDialog(
            title: const Text('Convidar cliente'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'E-mail do cliente',
                      hintText: 'cliente@exemplo.com',
                    ),
                    validator: validator,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        setStateSB(() { loading = true; error = null; });
                        try {
                          final room = await _api.inviteGuestByEmail(controller.text.trim());
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Convite enviado. Sala: ${room.name}')),
                            );
                            _load();
                          }
                        } catch (e) {
                          setStateSB(() {
                            error = e.toString().replaceFirst('Exception: ', '');
                            loading = false;
                          });
                        }
                      },
                child: loading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar convite'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        actions: [
          IconButton(
            icon: Icon(_onlyActive ? Icons.toggle_on : Icons.toggle_off),
            onPressed: () {
              setState(() {
                _onlyActive = !_onlyActive;
                _load();
              });
            },
            tooltip: _onlyActive ? 'Mostrar todas' : 'Mostrar ativas',
          ),
          if (_canInvite)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Convidar cliente',
              onPressed: _showInviteDialog,
            ),
        ],
      ),
      body: FutureBuilder<List<ChatRoom>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro ao carregar: ${snap.error}'));
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) return const Center(child: Text('Nenhuma conversa'));
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rooms[i];
              final subtitle = (r.lastMessage?.content?.trim().isNotEmpty ?? false)
                  ? r.lastMessage!.content
                  : 'Sem mensagens';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: r.active ? AppColors.infoLight : Colors.grey,
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (!r.active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Encerrada', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
                subtitle: Text(subtitle),
                onTap: () {
                  Navigator.pushNamed(context, '/chat_room', arguments: {
                    'roomId': r.id,
                    'roomName': r.name,
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _canInvite
          ? FloatingActionButton(
              onPressed: _showInviteDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
