import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../../domain/entities/user.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/auth_api_data_source.dart';
import '../../components/standartScreen.dart';
import '../../components/navbar.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final ProfileService _profileService = ProfileService(
    AuthRepositoryImpl(
      apiDataSource: AuthApiDataSource(),
      storageService: SecureStorageService(),
    ),
  );
  int _selectedIndex = 1;
  User? _user;

  @override
  void initState() {
    super.initState();
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
        _user = null;
      });
      print('Erro ao carregar usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Meu Perfil',
      showBackButton: false,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      child: _user == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Carregando perfil...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nome do usuário
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _user!.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email do usuário
                  Text(
                    _user!.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 40),

                  // Cards de ações
                  _buildActionCard(
                    icon: Icons.lock_outline,
                    title: 'Alterar Senha',
                    subtitle: 'Atualize sua senha de acesso',
                    color: Colors.blue,
                    onTap: () => _profileService.changePassword(context),
                  ),

                  const SizedBox(height: 16),

                  // adicionar futuramente
                  // _buildActionCard(
                  //   icon: Icons.settings_outlined,
                  //   title: 'Configurações',
                  //   subtitle: 'Personalize o aplicativo',
                  //   color: Colors.green,
                  //   onTap: () => _profileService.openSettings(context),
                  // ),

                  // const SizedBox(height: 16),
                  _buildActionCard(
                    icon: Icons.exit_to_app,
                    title: 'Sair do App',
                    subtitle: 'Encerrar sua sessão',
                    color: Colors.red,
                    onTap: () async {
                      await _showLogoutConfirmation();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Sair do App'),
            ],
          ),
          content: const Text('Tem certeza que deseja sair do aplicativo?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _profileService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}
