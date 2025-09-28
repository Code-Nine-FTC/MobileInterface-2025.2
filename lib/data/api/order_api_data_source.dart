import '../../domain/entities/order_item_response.dart';

import '../../domain/entities/order.dart';
import 'base_api_service.dart';

class OrderApiDataSource extends BaseApiService {
  /// Atualiza os itens de um pedido existente
  Future<bool> updateOrderItems(int orderId, Map<int, int> itemQuantities, DateTime withdrawDay) async {
  print('[DEBUG] IDs enviados para updateOrderItems: ${itemQuantities.keys.toList()}');
    // Converte o mapa para Map<String, int> para o backend, se necessário
    final Map<String, int> itemQuantitiesStr = itemQuantities.map((k, v) => MapEntry(k.toString(), v));
    final body = {
      'withdrawDay': withdrawDay.toIso8601String(),
      'itemQuantities': itemQuantitiesStr,
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

  Future<bool> completeOrder(int orderId) async {
    final response = await patch('/orders/complete/$orderId');
    return response.statusCode == 200;
  }
  Future<bool> cancelOrder(int orderId) async {
    final response = await patch('/orders/cancel/$orderId');
    return response.statusCode == 200;
  }
  Future<Order?> createOrder({
    required DateTime withdrawDay,
    required Map<String, int> itemQuantities,
  }) async {
    final response = await post(
      '/orders',
      data: {
        'withdrawDay': withdrawDay.toIso8601String(),
        'itemQuantities': itemQuantities,
      },
    );
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return Order.fromJson(response.data);
      } else {
        // Qualquer outro tipo de resposta (String, null, etc): considera sucesso
        return null;
      }
    } else {
      throw Exception('Erro ao criar pedido: ${response.data}');
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
    int? supplierId,
    int? sectionId,
  }) async {
    // Não enviar nenhum filtro para buscar todos os pedidos
    final response = await get(
      '/orders',
      queryParameters: null,
    );
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
