import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_api_service.dart';

class ItemApiDataSource {
  final BaseApiService _apiService = BaseApiService();

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    try {
      print('[ItemApiDataSource] Enviando JSON para backend: ${jsonEncode(item)}');
      
      final response = await _apiService.post('/items', data: item);
      
      print('[ItemApiDataSource] Status Code recebido: ${response.statusCode}');
      print('[ItemApiDataSource] Response Headers: ${response.headers}');
      print('[ItemApiDataSource] Response Data Type: ${response.data.runtimeType}');
      print('[ItemApiDataSource] Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar o tipo da resposta
        if (response.data is Map<String, dynamic>) {
          print('[ItemApiDataSource] Retornando Map válido');
          return response.data;
        } else if (response.data is String) {
          // Verificar se é JSON válido
          try {
            print('[ItemApiDataSource] Tentando fazer parse de String para JSON');
            final parsed = jsonDecode(response.data);
            if (parsed is Map<String, dynamic>) {
              return parsed;
            }
          } catch (e) {
            print('[ItemApiDataSource] String não é JSON válido, criando resposta genérica');
          }
          
          // Se não for JSON, criar uma resposta genérica baseada na string
          print('[ItemApiDataSource] Retornando Map genérico para resposta String');
          return {
            'success': true,
            'message': response.data.toString(),
            'statusCode': response.statusCode,
          };
        }
        
        // Se chegou aqui, retorna um Map genérico
        print('[ItemApiDataSource] Retornando Map genérico devido a tipo inesperado');
        return {
          'success': true,
          'message': 'Item criado com sucesso',
          'data': response.data,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMsg = response.data?.toString() ?? 'Erro desconhecido';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception('Falha ao criar item: $errorMsg');
      }
    } on DioException catch (e) {
      print('[ItemApiDataSource] DioException: ${e.type}');
      print('[ItemApiDataSource] DioException message: ${e.message}');
      print('[ItemApiDataSource] DioException response: ${e.response?.data}');
      
      String errorMsg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        errorMsg = e.response!.data['message'];
      }
      throw Exception('Falha ao criar item: $errorMsg');
    } catch (e) {
      print('[ItemApiDataSource] Erro geral: $e');
      print('[ItemApiDataSource] Erro tipo: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getItems( {String? sectionId, String? userRole}) async {
    try {
      Map<String, String> queryParams = {};

      if (userRole != 'ADMIN' && sectionId != null && sectionId.isNotEmpty) {
        queryParams['sectionId'] = sectionId;
        print('[ItemApiDataSource] Usuário $userRole - filtrando por sectionId: $sectionId');
      }

      else if (userRole == 'ADMIN' && sectionId != null && sectionId.isNotEmpty) {
        queryParams['sectionId'] = sectionId;
        print('[ItemApiDataSource] ADMIN - filtrando por seção específica: $sectionId');
      }
      else if (userRole == 'ADMIN') {
        print('[ItemApiDataSource] ADMIN - buscando todos os itens (sem filtro de seção)');
      }
      
      print('[ItemApiDataSource] Role: $userRole, SectionId: $sectionId');
      print('[ItemApiDataSource] Query params: $queryParams');
      
      final response = await _apiService.get('/items', queryParameters: queryParams);

      print('[ItemApiDataSource] Status Code: ${response.statusCode}');
      print('[ItemApiDataSource] Response Headers: ${response.headers}');
      print('[ItemApiDataSource] Response Data Type: ${response.data.runtimeType}');
      print('[ItemApiDataSource] Resposta bruta do backend: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('[ItemApiDataSource] Processando dados do tipo: ${data.runtimeType}');
        
        if (data is List) {
          print('[ItemApiDataSource] É uma lista com ${data.length} itens');
          final items = List<Map<String, dynamic>>.from(data);
          print('[DEBUG] itemIds retornados em getItems: ${items.map((e) => e['itemId']).toList()}');
          return items;
        } else if (data is Map && data.containsKey('content')) {
          print('[ItemApiDataSource] É um Map com content - content tem ${data['content'].length} itens');
          final items = List<Map<String, dynamic>>.from(data['content']);
          print('[DEBUG] itemIds retornados em getItems: ${items.map((e) => e['itemId']).toList()}');
          return items;
        } else {
          print('[ItemApiDataSource] Formato inesperado: $data');
          throw Exception('Formato de resposta inesperado: $data');
        }
      } else {
        print('[ItemApiDataSource] Status code não é 200: ${response.statusCode}');
        throw Exception('Falha ao buscar itens: ${response.data}');
      }
    } on DioException catch (e) {
      print('[ItemApiDataSource] DioException capturada:');
      print('[ItemApiDataSource] - Type: ${e.type}');
      print('[ItemApiDataSource] - Message: ${e.message}');
      print('[ItemApiDataSource] - Response status: ${e.response?.statusCode}');
      print('[ItemApiDataSource] - Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado. Você não tem permissão para acessar este recurso.');
      }
      throw Exception('Falha ao buscar itens: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('[ItemApiDataSource] Erro geral capturado: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getItemById(String id) async {
    try {
      final response = await _apiService.get('/items/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        throw Exception('Formato de resposta inesperado ao obter item $id: ${response.data}');
      } else if (response.statusCode == 404) {
        throw Exception('Item não encontrado');
      } else {
        throw Exception('Falha ao buscar item: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Item não encontrado');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado.');
      }
      throw Exception('Falha ao buscar item: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> getItemByQrCode(String uri) async {
    try {
      final response = await _apiService.get(uri);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        throw Exception('Formato de resposta inesperado ao obter item por QR: ${response.data}');
      } else if (response.statusCode == 404) {
        throw Exception('Item não encontrado por QR');
      } else {
        throw Exception('Falha ao buscar item por QR: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Item não encontrado por QR');
      }
      throw Exception('Falha ao buscar item por QR: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> updateItemStock(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.put('/items/$id', data: payload);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        throw Exception('Formato de resposta inesperado ao atualizar item $id: ${response.data}');
      } else {
        throw Exception('Falha ao atualizar item: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Falha ao atualizar item: ${e.response?.data ?? e.message}');
    }
  }
}
