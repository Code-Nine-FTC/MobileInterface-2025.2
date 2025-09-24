import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_api_service.dart';

class ItemApiDataSource {
  final BaseApiService _apiService = BaseApiService();

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item, String token) async {
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

  Future<List<Map<String, dynamic>>> getItems(String token, {String? sectionId, String? userRole}) async {
    try {
      Map<String, String> queryParams = {};
      
      // Se não for ADMIN, adiciona sectionId obrigatório (se não estiver vazio)
      if (userRole != 'ADMIN' && sectionId != null && sectionId.isNotEmpty) {
        queryParams['sectionId'] = sectionId;
      }
      // Se for ADMIN e especificar uma seção, adiciona sectionId
      else if (userRole == 'ADMIN' && sectionId != null && sectionId.isNotEmpty) {
        queryParams['sectionId'] = sectionId;
      }
      
      print('[ItemApiDataSource] Role: $userRole, SectionId: $sectionId');
      print('[ItemApiDataSource] Query params: $queryParams');
      print('[ItemApiDataSource] Token being used: ${token.substring(0, 10)}...');
      
      // Fazer a requisição com token manual no header
      final response = await _apiService.get(
        '/items', 
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('[ItemApiDataSource] Status Code: ${response.statusCode}');
      print('[ItemApiDataSource] Response Headers: ${response.headers}');
      print('[ItemApiDataSource] Response Data Type: ${response.data.runtimeType}');
      print('[ItemApiDataSource] Resposta bruta do backend: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('[ItemApiDataSource] Processando dados do tipo: ${data.runtimeType}');
        
        if (data is List) {
          print('[ItemApiDataSource] É uma lista com ${data.length} itens');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('content')) {
          print('[ItemApiDataSource] É um Map com content - content tem ${data['content'].length} itens');
          return List<Map<String, dynamic>>.from(data['content']);
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

  // Busca detalhes de um item por ID
  Future<Map<String, dynamic>> getItemById(String token, String id) async {
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
}
