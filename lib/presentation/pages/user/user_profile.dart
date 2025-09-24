import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../../domain/entities/user.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/auth_api_data_source.dart';


class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late final ProfileService _profileService;
  final authRepository = AuthRepositoryImpl(apiDataSource: AuthApiDataSource(), storageService: SecureStorageService());
  late User? _user;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(authRepository);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _profileService.getCurrentUser();
      setState(() {
        _user = user;
      });
    } catch (e) {
      setState(() {
        _user = null; // Defina como null em caso de erro
      });
      // Trate erro (ex: mostrar snackbar)
      print('Erro ao carregar usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Theme.of(context).primaryColor, // Usa tema de core/theme/
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator()) // Loading
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar (adicione imagem real se disponível)
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.headlineSmall, // Usa tema
                  ),
                  Text(
                    _user!.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock, color: Colors.blue),
                          title: const Text('Alterar Senha'),
                          onTap: () => _profileService.changePassword(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings, color: Colors.green),
                          title: const Text('Configurações do App'),
                          onTap: () => _profileService.openSettings(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sair do App'),
                          onTap: () async {
                            await _profileService.logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}