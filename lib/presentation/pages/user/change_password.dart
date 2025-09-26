import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../../domain/entities/user.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/auth_api_data_source.dart';
import '../../components/standartScreen.dart';
import '../../components/navbar.dart';
import 'package:flutter/material.dart';


class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  late final ProfileService _profileService;
  final authRepository = AuthRepositoryImpl(
    apiDataSource: AuthApiDataSource(),
    storageService: SecureStorageService(),
  );

  User? _user;
  int _selectedIndex = 0;
  final _formKey = GlobalKey<FormState>();
  String? _newPassword;
  String? _confirmPassword;
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
        _user = null;
      });
      print('Erro ao carregar usuário: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Atualizar Senha',
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
                    'Carregando ...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _user!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email do usuário
                  Text(
                    _user!.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Formulário de troca de senha
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nova senha',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _newPassword = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite a nova senha';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nova senha',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _confirmPassword = value,
                          validator: (value) {
                            if (value != _newPassword) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_user != null && _newPassword != null) {
                                 bool success = await _profileService.updatePassword(_user!.id, _newPassword!, _user!.name);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Senha atualizada com sucesso! Faça login novamente.')),
                                  );
                                  _profileService.logout();
                                  Navigator.pushReplacementNamed(context, '/login');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Falha ao atualizar a senha')),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Salvar nova senha'),
                        ),
                      ],
                    ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}