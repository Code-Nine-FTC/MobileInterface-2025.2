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
      String emsg = e.response?.data?.toString() ?? '';
      if (emsg.isEmpty) emsg = e.message ?? 'Erro desconhecido';
      throw Exception('Falha ao buscar item: $emsg');
    }
  }

  Future<Map<String, dynamic>> registerLoss(
    String itemId,
    int lostQuantity,
    String reason,
    String recordedById,
  ) async {
    try {
      print('[ItemApiDataSource] Registrando perda para item $itemId');
      print('[ItemApiDataSource] Quantidade perdida: $lostQuantity');
      print('[ItemApiDataSource] Motivo: $reason');
      print('[ItemApiDataSource] Registrado por: $recordedById');

      final data = {
        'reason': reason,
        'lostQuantity': lostQuantity,
        'itemId': int.tryParse(itemId) ?? itemId,
        'recordedById': int.tryParse(recordedById) ?? recordedById,
      };

      final response = await _apiService.post(
        '/items/loss',
        data: data,
      );

      print('[ItemApiDataSource] Status Code: ${response.statusCode}');
      print('[ItemApiDataSource] Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }

        final raw = response.data;
        if (raw is String) {
          try {
            final parsed = jsonDecode(raw);
            if (parsed is Map<String, dynamic>) return parsed;
          } catch (_) {
            return {
              'success': true,
              'message': raw,
              'statusCode': response.statusCode,
            };
          }
        }

        return {
          'success': true,
          'message': 'Perda registrada com sucesso',
          'statusCode': response.statusCode,
        };
      } else {
        final err = response.data;
        throw Exception('Falha ao registrar perda: $err');
      }
    } on DioException catch (e) {
      print('[ItemApiDataSource] DioException: ${e.type}');
      print('[ItemApiDataSource] DioException message: ${e.message}');
      print('[ItemApiDataSource] DioException response: ${e.response?.data}');

      if (e.response?.statusCode == 422) {
        String errorMsg = 'Dados inválidos';
        try {
          if (e.response?.data is Map && e.response!.data.containsKey('message')) {
            errorMsg = e.response!.data['message'];
          } else if (e.response?.data is String) {
            errorMsg = e.response!.data;
          }
        } catch (_) {}
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Item não encontrado');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado. Você não tem permissão para registrar perdas.');
      }

      final errorMsg = e.response?.data != null && e.response!.data.toString().isNotEmpty ? e.response!.data : (e.message ?? 'Erro desconhecido');
      throw Exception('Falha ao registrar perda: $errorMsg');
    } catch (e) {
      print('[ItemApiDataSource] Erro geral: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getItemLosses({
    String? itemId,
    String? recordedById,
    DateTime? startDate,
    DateTime? endDate,
    String? itemLossId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (itemId != null && itemId.isNotEmpty) queryParams['itemId'] = int.tryParse(itemId) ?? itemId;
      if (recordedById != null && recordedById.isNotEmpty) queryParams['recordedById'] = int.tryParse(recordedById) ?? recordedById;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (itemLossId != null && itemLossId.isNotEmpty) queryParams['itemLossId'] = int.tryParse(itemLossId) ?? itemLossId;

      print('[ItemApiDataSource] getItemLosses query: $queryParams');

      final response = await _apiService.get('/items/loss', queryParameters: queryParams);
      print('[ItemApiDataSource] getItemLosses status: ${response.statusCode}');
      print('[ItemApiDataSource] getItemLosses data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}));
        } else if (data is Map && data.containsKey('content')) {
          return List<Map<String, dynamic>>.from(data['content']);
        } else if (data is Map) {
          return [Map<String, dynamic>.from(data)];
        }
        throw Exception('Formato inesperado ao buscar perdas: $data');
      } else {
        throw Exception('Falha ao buscar perdas: ${response.data}');
      }
    } on DioException catch (e) {
      print('[ItemApiDataSource] DioException getItemLosses: ${e.message}');
      final status = e.response?.statusCode;
      if (status != null && status >= 500 && status < 600) {
        print('[ItemApiDataSource] Erro 5xx ao buscar perdas do item (status: $status). Retornando lista vazia para evitar crash.');
        return <Map<String, dynamic>>[];
      }
      String msg = e.response?.data?.toString() ?? '';
      if (msg.isEmpty) msg = e.message ?? 'Erro desconhecido';
      throw Exception('Falha ao buscar perdas: $msg');
    } catch (e) {
      print('[ItemApiDataSource] Erro em getItemLosses: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getItemByQrCode(String uri) async {
    try {
      // Normaliza URLs absolutas (ex.: http://127.0.0.1:8080/items?code=...) para rota relativa
      // Assim usamos sempre o baseUrl correto (10.0.2.2 no Android, localhost no desktop/web)
      final raw = uri.trim();
      String pathToGet;
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        final u = Uri.parse(raw);
        pathToGet = u.path + (u.hasQuery ? '?${u.query}' : '');
      } else {
        pathToGet = raw.startsWith('/') ? raw : '/$raw';
      }

      final response = await _apiService.get(pathToGet);

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

  // Suporte: buscar itens por filtros (ex.: itemCode) para obter o id após criação
  Future<List<Map<String, dynamic>>> searchItems({
    String? itemCode,
    String? sectionId,
    String? itemTypeId,
    bool? isActive,
    String? itemId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (itemCode != null && itemCode.isNotEmpty) queryParams['itemCode'] = itemCode;
      if (sectionId != null && sectionId.isNotEmpty) queryParams['sectionId'] = sectionId;
      if (itemTypeId != null && itemTypeId.isNotEmpty) queryParams['itemTypeId'] = itemTypeId;
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (itemId != null && itemId.isNotEmpty) queryParams['itemId'] = itemId;

      final response = await _apiService.get('/items', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('content')) {
          return List<Map<String, dynamic>>.from(data['content']);
        }
        throw Exception('Formato de resposta inesperado em searchItems: ${response.data}');
      }
      throw Exception('Falha ao buscar itens: ${response.data}');
    } on DioException catch (e) {
      throw Exception('Falha ao buscar itens: ${e.response?.data ?? e.message}');
    }
  }
}
