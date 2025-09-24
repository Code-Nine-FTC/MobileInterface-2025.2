import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_api_service.dart';

class ItemTypeApiDataSource {
  final BaseApiService _apiService = BaseApiService();

  Future<List<Map<String, dynamic>>> getItemTypes({
    int? itemTypeId,
    int? sectionId,
    int? lastUserId,
  }) async {
    try {
      // Montar query parameters
      final queryParams = <String, String>{};
      if (itemTypeId != null) queryParams['itemTypeId'] = itemTypeId.toString();
      if (sectionId != null) queryParams['sectionId'] = sectionId.toString();
      if (lastUserId != null) queryParams['lastUserId'] = lastUserId.toString();

      final response = await _apiService.get(
        '/item-types',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('[ItemTypeApiDataSource] Status Code: ${response.statusCode}');
      print('[ItemTypeApiDataSource] Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('content')) {
          // Suporte para paginação Spring
          return List<Map<String, dynamic>>.from(data['content']);
        } else {
          throw Exception('Formato de resposta inesperado: $data');
        }
      } else {
        throw Exception('Falha ao buscar tipos de item: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado.');
      }
      throw Exception('Falha ao buscar tipos de item: ${e.response?.data ?? e.message}');
    } catch (e) {

      rethrow;
    }
  }

  Future<Map<String, dynamic>> createItemType(Map<String, dynamic> itemType) async {
    try {
      final response = await _apiService.post('/item-types', data: itemType);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        String errorMsg = response.data?.toString() ?? 'Erro desconhecido';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception('Falha ao criar tipo de item: $errorMsg');
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        errorMsg = e.response!.data['message'];
      }
      throw Exception('Falha ao criar tipo de item: $errorMsg');
    }
  }
}
