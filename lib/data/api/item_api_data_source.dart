import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemApiDataSource {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item, String token) async {
    final jsonBody = jsonEncode(item);
    print('[ItemApiDataSource] Enviando JSON para backend: $jsonBody');
    final response = await http.post(
      Uri.parse('$_baseUrl/items/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonBody,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMsg = decoded['message'];
        }
      } catch (_) {}
      throw Exception('Falha ao criar item: $errorMsg');
    }
  }

  Future<List<Map<String, dynamic>>> getItems(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/items/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('[ItemApiDataSource] Resposta bruta do backend: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('content')) {
        // Suporte para paginação Spring
        return List<Map<String, dynamic>>.from(data['content']);
      } else {
        throw Exception('Formato de resposta inesperado: $data');
      }
    } else {
      throw Exception('Falha ao buscar itens: ${response.body}');
    }
  }
}
