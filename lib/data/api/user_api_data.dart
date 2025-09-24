import 'package:mobile_interface_2025_2/domain/entities/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class UserApiData {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<User> getCurrentUser(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }
}