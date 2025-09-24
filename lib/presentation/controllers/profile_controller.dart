import 'package:flutter/material.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/auth/auth_repository.dart'; 
import '../../../core/utils/secure_storage_service.dart'; 
import '../../../routes/home-router.dart'; 
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
    Navigator.pushNamed(context, '/changePassword');
  }

  void openSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }
}