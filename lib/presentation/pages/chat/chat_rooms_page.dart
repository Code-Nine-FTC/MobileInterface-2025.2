import 'package:flutter/material.dart';
import '../../../data/api/chat_api_data_source.dart';
import '../../../data/models/chat_room.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../components/standartScreen.dart';

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
    return StandardScreen(
      title: 'Conversas',
      showBackButton: true,
      actions: [
        IconButton(
          icon: Icon(
            _onlyActive ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
            color: Colors.white,
          ),
          tooltip: _onlyActive ? 'Mostrar todas' : 'Mostrar ativas',
          onPressed: () {
            setState(() {
              _onlyActive = !_onlyActive;
              _load();
            });
          },
        ),
        if (_canInvite)
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            tooltip: 'Convidar cliente',
            onPressed: _showInviteDialog,
          ),
      ],
      child: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<ChatRoom>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Erro ao carregar: ${snap.error}'));
            }
            final rooms = snap.data ?? [];
            if (rooms.isEmpty) {
              return const Center(child: Text('Nenhuma conversa'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: rooms.length,
              itemBuilder: (_, i) {
                final r = rooms[i];
                final subtitle = (r.lastMessage?.content?.trim().isNotEmpty ?? false)
                    ? r.lastMessage!.content
                    : 'Sem mensagens';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: (r.active ? AppColors.infoLight : Colors.red).withValues(alpha: 0.15),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: r.active
                              ? [AppColors.infoLight, AppColors.primaryLight]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        if (!r.active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text('Encerrada', style: TextStyle(color: Colors.red, fontSize: 11)),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    onTap: () async {
                      final res = await Navigator.pushNamed(context, '/chat_room', arguments: {
                        'roomId': r.id,
                        'roomName': r.name,
                      });
                      if (res == 'deleted') {
                        _load();
                      }
                    },
                    trailing: _buildDeleteAction(r),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeleteAction(ChatRoom room) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
      tooltip: room.active ? 'Encerrar conversa' : 'Excluir conversa',
      onPressed: () async {
        await _confirmAndDelete(room);
      },
    );
  }

  Future<void> _confirmAndDelete(ChatRoom room) async {
    final isActive = room.active;
    final actionLabel = isActive ? 'encerrar' : 'excluir definitivamente';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isActive ? 'Encerrar conversa' : 'Excluir conversa'),
          content: Text(
            isActive
                ? 'A conversa ficará marcada como encerrada e não receberá novas mensagens. Deseja continuar?'
                : 'Esta ação removerá a conversa da lista (se suportado pelo servidor). Deseja continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isActive ? 'Encerrar' : 'Excluir')),
          ],
        );
      },
    );
    if (confirm != true) return;
    try {
      if (isActive) {
        await _api.closeRoom(room.id);
      } else {
        // Tenta exclusão definitiva; se falhar, apenas mostra erro
        await _api.deleteRoom(room.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversa ${actionLabel} com sucesso.')),
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao ${actionLabel}: ${e.toString()}')),
      );
    }
  }
}
