import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemTypeApiDataSource {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<List<Map<String, dynamic>>> getItemTypes({
    int? itemTypeId,
    int? sectionId,
    int? lastUserId,
    required String token,
  }) async {
    // Montar query parameters
    final queryParams = <String, String>{};
    if (itemTypeId != null) queryParams['itemTypeId'] = itemTypeId.toString();
    if (sectionId != null) queryParams['sectionId'] = sectionId.toString();
    if (lastUserId != null) queryParams['lastUserId'] = lastUserId.toString();

    final uri = Uri.parse('$_baseUrl/item-types').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print('[ItemTypeApiDataSource] URL usada: $uri');
    print('[ItemTypeApiDataSource] Resposta: ${response.body}');

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
      throw Exception('Falha ao buscar tipos de item: ${response.body}');
    }
  }


  Future<Map<String, dynamic>> createItemType(
      Map<String, dynamic> itemType, String token) async {
    final jsonBody = jsonEncode(itemType);
    print('[ItemTypeApiDataSource] Enviando JSON para backend: $jsonBody');
    final response = await http.post(
      Uri.parse('$_baseUrl/item-types/'),
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
      throw Exception('Falha ao criar tipo de item: $errorMsg');
    }
  }

}
