import 'package:flutter/material.dart';
import '../../../domain/entities/user.dart'; // Entidade User
import '../../../domain/auth/auth_repository.dart'; // Repositório de auth
import '../../../core/utils/secure_storage_service.dart'; // Armazenamento seguro
import '../../../routes/home-router.dart'; // Rotas (ajuste conforme necessário)
import '../../data/api/user_api_data.dart';

class ProfileService {
  final AuthRepository _authRepository;
  final UserApiData _userApiData = UserApiData();

  ProfileService(this._authRepository);

  Future<User?> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  void changePassword(BuildContext context) {
    Navigator.pushNamed(context, '/changePassword'); // Rota para alteração
  }

  void openSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings'); // Rota para configurações
  }
}