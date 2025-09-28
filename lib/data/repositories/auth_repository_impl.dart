import '../../core/utils/secure_storage_service.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../api/auth_api_data_source.dart'; // Importe o arquivo renomeado
import '../models/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiDataSource apiDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({required this.apiDataSource, required this.storageService});

  @override
  Future<User?> login(String email, String password) async {
    try {
      final response = await apiDataSource.login(email, password);
      return response;
    } catch (e) {
      // se der erro no login garante que qualquer coisa em token seja removida
      await logout();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await storageService.deleteToken();
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = await storageService.getUser();
    final token = await storageService.getToken();
    if (user == null || token == null) {
      await logout();
      return null;
    }
    return user;
  }
}