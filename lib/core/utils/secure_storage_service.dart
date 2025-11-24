import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_interface_2025_2/domain/entities/user.dart';
import 'dart:convert'; // Adicione este import para jsonEncode/jsonDecode


class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  // salva o token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // salva o id do usuário
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }

  Future<void> saveChatRoomId(String chatRoomId) async {
    await _storage.write(key: 'chat_room_id', value: chatRoomId);
  }

  Future<String?> getChatRoomId() async {
    return await _storage.read(key: 'chat_room_id');
  }

  Future<User?> getUser() async {
    final userData = await _storage.read(key: 'user');
    if (userData == null) return null;
    print(userData);

    return User.fromJson(jsonDecode(userData));
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  // pega o token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // remove o token usado no logout
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.deleteAll();
  }
}