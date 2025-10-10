import 'package:dio/dio.dart';
import '../models/expiry_summary_model.dart';
import '../models/expiry_item_model.dart';

class PharmacyApiDataSource {
  final Dio _dio;

  PharmacyApiDataSource(this._dio);

  Future<ExpirySummaryModel> getExpirySummary(int days) async {
    try {
      final response = await _dio.get(
        '/api/pharmacy/items/expiry-summary',
        queryParameters: {'days': days},
      );
      return ExpirySummaryModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao buscar resumo de vencimentos: $e');
    }
  }

  Future<Map<String, List<ExpiryItemModel>>> getExpiryList(int days, {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/pharmacy/items/expiry-list',
        queryParameters: {
          'days': days,
          'page': page,
          'size': size,
        },
      );
      
      final data = response.data;
      
      final expiredItems = (data['expired'] as List?)
          ?.map((item) => ExpiryItemModel.fromJson(item))
          .toList() ?? [];
      
      final expiringSoonItems = (data['expiringSoon'] as List?)
          ?.map((item) => ExpiryItemModel.fromJson(item))
          .toList() ?? [];
      
      return {
        'expired': expiredItems,
        'expiringSoon': expiringSoonItems,
      };
    } catch (e) {
      throw Exception('Erro ao buscar lista de vencimentos: $e');
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      await _dio.delete('/api/pharmacy/items/$itemId');
    } catch (e) {
      throw Exception('Erro ao excluir item: $e');
    }
  }
}
