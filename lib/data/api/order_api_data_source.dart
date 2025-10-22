
import 'dart:convert';
import '../../domain/entities/order_item_response.dart';

import '../../domain/entities/order.dart';
import 'base_api_service.dart';
import 'package:dio/dio.dart';

class OrderApiDataSource extends BaseApiService {
  String _yyyyMmDd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
  /// Atualiza os itens de um pedido existente
  Future<bool> updateOrderItems(int orderId, Map<int, int> itemQuantities, DateTime withdrawDay, {int? consumerSectionId}) async {
  print('[DEBUG] IDs enviados para updateOrderItems: ${itemQuantities.keys.toList()}');
    // Converte o mapa para Map<String, int> para o backend, se necessário
    final Map<String, int> itemQuantitiesStr = itemQuantities.map((k, v) => MapEntry(k.toString(), v));
    final body = {
      // Backend pode esperar apenas a data (yyyy-MM-dd)
      'withdrawDay': _yyyyMmDd(withdrawDay),
      'itemQuantities': itemQuantitiesStr,
      if (consumerSectionId != null) 'consumerSectionId': consumerSectionId,
    };
    print('[OrderApiDataSource] Enviando updateOrderItems: $body');
    final response = await put(
      '/orders/$orderId',
      data: body,
    );
    return response.statusCode == 200;
  }

  Future<List<OrderItemResponse>> getOrderItemsByOrderId(int orderId) async {
    final response = await get('/orders/items/$orderId');
    print('Resposta bruta da API /orders/items/$orderId:');
    print(response.data);
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((e) => OrderItemResponse.fromJson(e))
          .toList();
    }
    return [];
  }
  Future<bool> approveOrder(int orderId) async {
    final response = await patch('/orders/approve/$orderId');
    return response.statusCode == 200;
  }

  Future<bool> processOrder(int orderId) async {
    final response = await patch('/orders/process/$orderId');
    return response.statusCode == 200;
  }

  Future<bool> completeOrder(int orderId, DateTime withdrawDay) async {
    // Backend espera LocalDateTime ISO-8601 completo (ex: "2025-10-20T15:00:00")
    final body = jsonEncode(withdrawDay.toIso8601String());
    final response = await patch(
      '/orders/complete/$orderId',
      data: body,
      options: Options(contentType: 'application/json'),
    );
    return response.statusCode == 200;
  }
  Future<bool> cancelOrder(int orderId) async {
    final response = await patch('/orders/cancel/$orderId');
    return response.statusCode == 200;
  }
  Future<Order?> createOrder({
    required Map<String, int> itemQuantities,
    required int consumerSectionId,
    DateTime? withdrawDay,
    required String orderNumber, // obrigatório: número manual do pedido
  }) async {
    // Fluxo sem fornecedor: envia apenas itemQuantities e opcionais sectionId/withdrawDay
    final payload = {
      'itemQuantities': itemQuantities,
      'consumerSectionId': consumerSectionId,
      if (withdrawDay != null) 'withdrawDay': _yyyyMmDd(withdrawDay),
      'orderNumber': orderNumber.trim(),
    };
    print('[OrderApiDataSource] POST /orders payload: $payload');
    try {
      final response = await post('/orders', data: payload);
      print('[OrderApiDataSource] createOrder status=${response.statusCode} data=${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend retorna { id: <novoId> } — não precisamos parsear Order completo
        return null;
      }
      throw Exception('Erro ao criar pedido: ${response.data}');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final msg = data?.toString() ?? e.message ?? 'Erro desconhecido ao criar pedido';
      if (code == 409) {
        throw Exception('Número do pedido já existente. Escolha outro.');
      }
      if (code == 400) {
        if (msg.toLowerCase().contains('consumersectionid')) {
          throw Exception('consumerSectionId é obrigatório ou inválido.');
        }
        if (msg.toLowerCase().contains('consumer')) {
          throw Exception('A seção informada não é do tipo CONSUMER.');
        }
      }
      // Não tentamos criar sem orderNumber porque ele é obrigatório no app.
      throw Exception('Erro ao criar pedido: $msg');
    }
  }

  Future<Order?> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await put(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    if (response.statusCode == 200) {
      return Order.fromJson(response.data);
    }
    return null;
  }

  Future<List<Order>> getOrders({
    int? orderId,
    String? status,
    int? userId,
    int? sectionId,
  }) async {
    final Map<String, dynamic> qp = {};
    if (sectionId != null) qp['sectionId'] = sectionId;
    if (orderId != null) qp['orderId'] = orderId;
    if (status != null) qp['status'] = status;
    if (userId != null) qp['userId'] = userId;
    final response = await get('/orders', queryParameters: qp.isEmpty ? null : qp);
    if (response.statusCode == 200) {
      final data = response.data;
      print('Resposta bruta da API /orders:');
      print(data);
      if (data is List) {
        return data.map((e) => Order.fromJson(e)).toList();
      } else if (data is Map<String, dynamic>) {
        // Tenta encontrar uma lista dentro do JSON (ex: 'content', 'orders', etc.)
        final possibleListKeys = ['content', 'orders', 'data', 'results'];
        for (final key in possibleListKeys) {
          if (data[key] is List) {
            return (data[key] as List).map((e) => Order.fromJson(e)).toList();
          }
        }
        // Caso venha um único pedido como objeto
        return [Order.fromJson(data)];
      } else {
        return [];
      }
    }
    return [];
  }

  Future<Order?> getOrderById(int id) async {
    final response = await get('/orders/$id');
    if (response.statusCode == 200) {
      return Order.fromJson(response.data);
    }
    return null;
  }
}
