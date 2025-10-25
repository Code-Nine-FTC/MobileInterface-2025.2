import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderApiDataSource extends BaseApiService {
  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await get('/purchase-orders/all');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => PurchaseOrder.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (data is Map<String, dynamic>) {
        // tenta localizar lista em keys comuns
        final possible = ['content', 'data', 'results', 'purchaseOrders'];
        for (final k in possible) {
          if (data[k] is List) return (data[k] as List).map((e) => PurchaseOrder.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        return [PurchaseOrder.fromJson(Map<String, dynamic>.from(data))];
      }
    }
    return [];
  }

  Future<PurchaseOrder?> getPurchaseOrderById(int id) async {
    final response = await get('/purchase-orders/$id');
    if (response.statusCode == 200) {
      return PurchaseOrder.fromJson(Map<String, dynamic>.from(response.data));
    }
    return null;
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      final response = await patch('/purchase-orders/$id/status', data: {'status': status});
      return response.statusCode == 200;
    } on DioException catch (e) {
      // log opcional
      print('[PurchaseOrderApi] updateStatus erro: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }
}
