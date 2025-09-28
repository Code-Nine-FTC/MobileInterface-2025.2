import 'package:flutter/material.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/auth/auth_repository.dart'; 
import '../../data/api/user_api_data.dart';

class ProfileService {
  final AuthRepository _authRepository;
  final UserApiData _userApiData = UserApiData();

  ProfileService(this._authRepository);
  

  Future<User?> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }

  Future<bool> updatePassword(int userId, String password, String name) async {
    return await _userApiData.updatePassword(userId, password, name);
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