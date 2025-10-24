import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mobile_interface_2025_2/domain/entities/user.dart';
import 'base_api_service.dart';
import '../../core/utils/secure_storage_service.dart';

class AuthApiDataSource {
  final _baseApiService = BaseApiService();
  final _secureStorage = SecureStorageService();
  
  

  String? _extractSessionId(Map<String, dynamic> data) {
    // Tenta sections[0].id
    if (data['sections'] is List && data['sections'].isNotEmpty) {
      final firstSection = data['sections'][0];
      if (firstSection is Map && firstSection['id'] != null) {
        return firstSection['id'].toString();
      }
    }
    // Tenta sectionIds[0]
    if (data['sectionIds'] is List && data['sectionIds'].isNotEmpty) {
      return data['sectionIds'][0].toString();
    }
    // Fallbacks diretos
    return data['sessionId']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await _baseApiService.post('/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 400) throw Exception('Credenciais inválidas');
      if (response.statusCode == 500) throw Exception('Erro no servidor, tente novamente mais tarde');
      if (response.statusCode == 401 || response.statusCode == 403) throw Exception('Não autorizado');

      final data = response.data ;
      print(  '[AuthAPI] Resposta do login: $data');
      final token = data['token'];
      final role = data['role'];
      final userId = data['Id'];
      String? sessionId = _extractSessionId(data);

      if (token == null || role == null || sessionId == null || userId == null) {
        throw Exception('Token ou Role não recebido do servidor');
      }
      await _secureStorage.saveToken(token);
      User? user = await getProfile(userId);
      user?.sessionId = sessionId;
      user?.role = role;
      if (user != null) {
        await _secureStorage.saveUser(user);
        print('[AuthAPI] Usuário salvo: ${user.toJson()}');
      }
      await _secureStorage.saveUserId(userId.toString());

      return user;
    }
    catch(e){
      // Normaliza erros do Dio para mensagens curtas e amigáveis
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 400 || code == 401 || code == 403) {
          throw Exception('Email ou senha incorretos');
        }
        if (code == 500) {
          throw Exception('Erro no servidor, tente novamente mais tarde');
        }
        throw Exception('Não foi possível entrar. Verifique sua conexão e tente novamente.');
      }
      print('[AuthAPI] Erro no login: ${e.toString()}');
      throw Exception('Email ou senha incorretos');
    }
  }

  Future<User?> getProfile(int userId) async {
    final response = await _baseApiService.get('/users/$userId');
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar perfil: ${response.statusMessage}');
    }
    final data = response.data is Map<String, dynamic> ? response.data : jsonDecode(response.data);
    return User.fromJson(data);
  }
}