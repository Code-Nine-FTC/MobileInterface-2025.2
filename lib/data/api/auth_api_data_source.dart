import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mobile_interface_2025_2/domain/entities/user.dart';
import '../models/user_info.dart';
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
      final userId = data['Id'] ?? data['id'] ?? data['userId'];
      String? sessionId = _extractSessionId(data);

      // Para GUEST, extrair chatRoomId da resposta
      String? chatRoomId;
      if (role == 'GUEST' && data['chatRoom'] != null) {
        chatRoomId = data['chatRoom']['id']?.toString();
        if (chatRoomId != null) {
          await _secureStorage.saveChatRoomId(chatRoomId);
          print('[AuthAPI] ChatRoomId salvo para guest: $chatRoomId');
        }
      }

      if (token == null || role == null || userId == null) {
        throw Exception('Token ou Role não recebido do servidor');
      }
      await _secureStorage.saveToken(token);
      // Constrói usuário mínimo a partir do payload do login
      User userMin = User(
        id: int.parse(userId.toString()),
        name: (data['name'] ?? data['username'] ?? email).toString(),
        email: (data['email'] ?? email).toString(),
        sessionId: sessionId,
        role: role,
      );
      // Tenta enriquecer com perfil; se falhar (403/404), segue com userMin
      try {
        final detailed = await getProfile(userMin.id);
        if (detailed != null) {
          userMin = User(
            id: detailed.id,
            name: detailed.name,
            email: detailed.email,
            sessionId: sessionId,
            role: role,
          );
        }
      } catch (_) {}

      await _secureStorage.saveUser(userMin);
      print('[AuthAPI] Usuário salvo: ${userMin.toJson()}');
      await _secureStorage.saveUserId(userId.toString());

      return userMin;
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
    Response resp;
    try {
      resp = await _baseApiService.get('/api/users/$userId');
    } on DioException catch (e) {
      // fallback para caminhos antigos
      resp = await _baseApiService.get('/users/$userId');
    }
    if (resp.statusCode != 200) {
      throw Exception('Falha ao carregar perfil: ${resp.statusMessage}');
    }
    final data = resp.data is Map<String, dynamic> ? resp.data : jsonDecode(resp.data);
    return User.fromJson(data);
  }

  /// Obtém informações do usuário autenticado (USER ou GUEST)
  /// Usado para determinar o tipo de usuário e redirecionar corretamente
  Future<UserInfo> getUserInfo() async {
    try {
      final response = await _baseApiService.get('/api/auth/me');
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao obter informações do usuário');
      }

      final data = response.data is Map<String, dynamic> 
          ? response.data 
          : jsonDecode(response.data);
      
      print('[AuthAPI] Resposta do /auth/me: $data');
      return UserInfo.fromJson(data);
    } catch (e) {
      print('[AuthAPI] Erro ao obter UserInfo, tentando fallback: ${e.toString()}');
      
      // Fallback: usar dados do storage
      final user = await _secureStorage.getUser();
      if (user == null) {
        throw Exception('Usuário não encontrado no storage');
      }
      
      if (user.role == 'GUEST') {
        // Para guest, obter chatRoomId do storage
        final chatRoomId = await _secureStorage.getChatRoomId();
        print('[AuthAPI] Guest detectado - ChatRoomId do storage: $chatRoomId');
        
        return UserInfo(
          id: user.id,
          name: user.name,
          email: user.email,
          userType: 'GUEST',
          chatRoomId: chatRoomId,
        );
      } else {
        // Para USER normal
        return UserInfo(
          id: user.id,
          name: user.name,
          email: user.email,
          userType: 'USER',
          role: user.role,
          sessionId: user.sessionId,
        );
      }
    }
  }
}