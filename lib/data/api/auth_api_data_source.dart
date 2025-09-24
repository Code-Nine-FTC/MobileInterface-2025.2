import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiDataSource {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('[AUTH] Resposta completa do login: $data');
      
      final token = data['token'];
      final role = data['role'];
      
      // Pegar sectionId do response
      String? sessionId;
      
      // Tentar pegar de sections[0].id
      if (data['sections'] != null && data['sections'] is List && data['sections'].isNotEmpty) {
        final firstSection = data['sections'][0];
        if (firstSection is Map && firstSection.containsKey('id')) {
          sessionId = firstSection['id'].toString();
        }
      }
      
      // Fallback para sectionIds se existir
      if (sessionId == null && data['sectionIds'] != null && data['sectionIds'] is List && data['sectionIds'].isNotEmpty) {
        sessionId = data['sectionIds'][0].toString();
      }
      
      // Fallback para outros campos
      sessionId ??= data['sessionId']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();
      
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print('[AUTH] Token salvo: $token');
      }
      if (role != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        print('[AUTH] Role salvo: $role');
      }
      if (sessionId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_id', sessionId);
        print('[AUTH] SessionID salvo: $sessionId');
      } else {
        print('[AUTH] SessionID não encontrado no response');
      }
      return data;
    } else {
      throw Exception('Falha no login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/users/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Token inválido ou expirado');
    }
  }
}