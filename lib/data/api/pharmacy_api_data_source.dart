import 'package:dio/dio.dart';
import '../models/expiry_summary_model.dart';
import '../models/expiry_item_model.dart';

class PharmacyApiDataSource {
  final Dio _dio;

  PharmacyApiDataSource(this._dio);

  Future<ExpirySummaryModel> getExpirySummary(int days) async {
    try {
      print('[PharmacyAPI] Chamando GET /api/pharmacy/items/expiry-summary?days=$days');
      final response = await _dio.get(
        '/api/pharmacy/items/expiry-summary',
        queryParameters: {'days': days},
      );
      print('[PharmacyAPI] Status Code: ${response.statusCode}');
      print('[PharmacyAPI] Resposta do resumo: ${response.data}');
      return ExpirySummaryModel.fromJson(response.data);
    } catch (e) {
      print('[PharmacyAPI] ERRO ao buscar resumo: $e');
      if (e is DioException) {
        print('[PharmacyAPI] Response data: ${e.response?.data}');
        print('[PharmacyAPI] Response headers: ${e.response?.headers}');
        print('[PharmacyAPI] Request headers: ${e.requestOptions.headers}');
      }
      throw Exception('Erro ao buscar resumo de vencimentos: $e');
    }
  }

  Future<Map<String, List<ExpiryItemModel>>> getExpiryList(int days, {int page = 0, int size = 20}) async {
    try {
      print('[PharmacyAPI] Chamando GET /api/pharmacy/items/expiry-list?days=$days&page=$page&size=$size');
      final response = await _dio.get(
        '/api/pharmacy/items/expiry-list',
        queryParameters: {
          'days': days,
          'page': page,
          'size': size,
        },
      );
      
      print('[PharmacyAPI] Status: ${response.statusCode}');
      print('[PharmacyAPI] Resposta RAW (página $page):');
      print('  expired: ${(response.data['expired'] as List?)?.length ?? 0} itens');
      print('  expiringSoon: ${(response.data['expiringSoon'] as List?)?.length ?? 0} itens');
      
      final data = response.data;
      
      print('[PharmacyAPI] Processando itens vencidos...');
      final expiredItems = (data['expired'] as List?)
          ?.map((item) => ExpiryItemModel.fromJson(item))
          .toList() ?? [];
      print('[PharmacyAPI] ${expiredItems.length} itens vencidos processados');
      
      if (expiredItems.isNotEmpty) {
        print('[PharmacyAPI] Primeiro item vencido: ${expiredItems.first.name} - ${expiredItems.first.expireDate}');
      }
      
      print('[PharmacyAPI] Processando itens a vencer...');
      final expiringSoonItems = (data['expiringSoon'] as List?)
          ?.map((item) => ExpiryItemModel.fromJson(item))
          .toList() ?? [];
      print('[PharmacyAPI] ${expiringSoonItems.length} itens a vencer processados');
      
      if (expiringSoonItems.isNotEmpty) {
        print('[PharmacyAPI] Primeiro item a vencer: ${expiringSoonItems.first.name} - ${expiringSoonItems.first.expireDate}');
      }
      
      return {
        'expired': expiredItems,
        'expiringSoon': expiringSoonItems,
      };
    } catch (e) {
      print('[PharmacyAPI] ERRO ao buscar lista: $e');
      throw Exception('Erro ao buscar lista de vencimentos: $e');
    }
  }
}
