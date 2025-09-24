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

  Future<List<Map<String, dynamic>>> getItems(String token, {String? sectionId, String? userRole}) async {
    Map<String, String> queryParams = {};
    
    // Se não for ADMIN, adiciona sectionId obrigatório
    if (userRole != 'ADMIN' && sectionId != null) {
      queryParams['sectionId'] = sectionId;
    }
    // Se for ADMIN e especificar uma seção, adiciona sectionId
    else if (userRole == 'ADMIN' && sectionId != null && sectionId.isNotEmpty) {
      queryParams['sectionId'] = sectionId;
    }
    
    final uri = Uri.parse('$_baseUrl/items/').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    
    print('[ItemApiDataSource] Role: $userRole, SectionId: $sectionId');
    print('[ItemApiDataSource] URL final: $uri');
    
    final response = await http.get(
      uri,
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
        return List<Map<String, dynamic>>.from(data['content']);
      } else {
        throw Exception('Formato de resposta inesperado: $data');
      }
    } else {
      throw Exception('Falha ao buscar itens: ${response.body}');
    }
  }

  // Busca detalhes de um item por ID
  Future<Map<String, dynamic>> getItemById(String token, String id) async {
    final uri = Uri.parse('$_baseUrl/items/$id');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Formato de resposta inesperado ao obter item $id: ${response.body}');
    } else if (response.statusCode == 404) {
      throw Exception('Item não encontrado');
    } else {
      throw Exception('Falha ao buscar item: ${response.body}');
    }
  }
}
