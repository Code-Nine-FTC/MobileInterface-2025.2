import 'dart:convert';
import 'package:mobile_interface_2025_2/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_api_service.dart';
import '../../core/utils/secure_storage_service.dart';

class AuthApiDataSource {
  final _baseApiService = BaseApiService();
  final _secureStorage = SecureStorageService();
  late final SharedPreferences prefs;
  AuthApiDataSource() {
    _init();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
  }

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

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _baseApiService.post('/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 400) throw Exception('Credenciais inválidas');
      if (response.statusCode == 500) throw Exception('Erro no servidor, tente novamente mais tarde');
      if (response.statusCode == 401 || response.statusCode == 403) throw Exception('Não autorizado');

      final data = response.data is Map<String, dynamic> ? response.data : jsonDecode(response.data);
      final token = data['token'];
      final role = data['role'];
      final sessionId = _extractSessionId(data);
      
      if (token == null || role == null || sessionId == null) {
        throw Exception('Token ou Role não recebido do servidor');
      }

      // Salvar token e dados no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_role', role);
      await prefs.setString('session_id', sessionId);
      
      // Também salvar no SecureStorageService para uso do BaseApiService
      await _secureStorage.saveToken(token);
      await _secureStorage.saveUserId(sessionId);
      
      print('[AuthAPI] Token salvo: ${token.substring(0, 10)}...');
      print('[AuthAPI] Role salva: $role');
      print('[AuthAPI] SessionId salvo: $sessionId');

      return data;
    }
    catch(e){
      print('[AuthAPI] Erro no login: ${e.toString()}');
      rethrow;
    }
  }

  Future<User?> getProfile(int userId) async {
    final response = await _baseApiService.get('/users/$userId');
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar perfil: ${response.statusMessage}');
    }
    return User.fromJson(jsonDecode(response.data));
  }
}