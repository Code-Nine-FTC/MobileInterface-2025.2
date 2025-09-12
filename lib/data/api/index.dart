import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
    static const String _baseUrl = 'http://10.0.2.2:8080';

    Future<Map<String, dynamic>> login(String username, String password) async {
        final response = await http.post(
            Uri.parse('$_baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
        );

        if (response.statusCode == 200) {
            return jsonDecode(response.body);
        } else {
            throw Exception('Failed to login');
        }
    }
}