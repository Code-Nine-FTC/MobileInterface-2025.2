import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  // salva o token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // pega o token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // remove o token usado no logout
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}