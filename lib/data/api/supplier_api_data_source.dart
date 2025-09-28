import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_api_service.dart';

class SupplierApiDataSource {
  final BaseApiService _apiService = BaseApiService();

  Future<List<Map<String, dynamic>>> getSuppliers({
    int? supplierId,
    int? sectionId,
    String? userRole,
  }) async {
    try {
      Map<String, String> queryParams = {};
      
      if (supplierId != null) queryParams['supplierId'] = supplierId.toString();
      
      // Para usuários não-ADMIN, sempre adicionar sectionId se fornecido
      if (userRole != 'ADMIN' && sectionId != null) {
        queryParams['sectionId'] = sectionId.toString();
        print('[SupplierApiDataSource] Usuário $userRole - filtrando por sectionId: $sectionId');
      } else if (userRole == 'ADMIN') {
        print('[SupplierApiDataSource] Usuário ADMIN - buscando todos os fornecedores');
      }
      
      final response = await _apiService.get(
        '/suppliers', 
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('[SupplierApiDataSource] Processing data type: ${data.runtimeType}');
        
        if (data is List) {
          print('[SupplierApiDataSource] Lista com ${data.length} fornecedores');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('content')) {
          print('[SupplierApiDataSource] Map paginado com ${data['content'].length} fornecedores');
          return List<Map<String, dynamic>>.from(data['content']);
        } else {
          print('[SupplierApiDataSource] Formato inesperado: $data');
          throw Exception('Formato de resposta inesperado: $data');
        }
      } else {
        print('[SupplierApiDataSource] Status code não é 200: ${response.statusCode}');
        throw Exception('Falha ao buscar fornecedores: ${response.data}');
      }
    } on DioException catch (e) {
      
      if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado. Você não tem permissão para acessar este recurso.');
      }
      throw Exception('Falha ao buscar fornecedores: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('[SupplierApiDataSource] Erro geral: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSupplierById(String supplierId) async {
    try {
      final response = await _apiService.get('/suppliers/$supplierId');

      if (response.statusCode == 200) {
        final data = response.data;
        print('[SupplierApiDataSource] getSupplierById($supplierId) => $data');
        if (data is Map<String, dynamic>) return data;
        throw Exception('Formato de resposta inesperado ao obter fornecedor $supplierId: ${response.data}');
      } else if (response.statusCode == 404) {
        throw Exception('Fornecedor não encontrado');
      } else {
        throw Exception('Falha ao buscar fornecedor: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Fornecedor não encontrado');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token expirado ou inválido. Faça login novamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado.');
      }
      throw Exception('Falha ao buscar fornecedor: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('[SupplierApiDataSource] Erro geral: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> supplier) async {
    try {
      print('[SupplierApiDataSource] Enviando JSON: ${jsonEncode(supplier)}');
      
      final response = await _apiService.post('/suppliers', data: supplier);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        String errorMsg = response.data?.toString() ?? 'Erro desconhecido';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception('Falha ao criar fornecedor: $errorMsg');
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        errorMsg = e.response!.data['message'];
      }
      throw Exception('Falha ao criar fornecedor: $errorMsg');
    }
  }

  Future<Map<String, dynamic>> updateSupplier(String supplierId, Map<String, dynamic> supplier) async {
    try {
      print('[SupplierApiDataSource] Atualizando fornecedor $supplierId: ${jsonEncode(supplier)}');
      
      final response = await _apiService.put('/suppliers/$supplierId', data: supplier);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        String errorMsg = response.data?.toString() ?? 'Erro desconhecido';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception('Falha ao atualizar fornecedor: $errorMsg');
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        errorMsg = e.response!.data['message'];
      }
      throw Exception('Falha ao atualizar fornecedor: $errorMsg');
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    try {
      final response = await _apiService.delete('/suppliers/$supplierId');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        String errorMsg = response.data?.toString() ?? 'Erro desconhecido';
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception('Falha ao excluir fornecedor: $errorMsg');
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        errorMsg = e.response!.data['message'];
      }
      throw Exception('Falha ao excluir fornecedor: $errorMsg');
    }
  }
}