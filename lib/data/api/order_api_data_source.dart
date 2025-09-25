
import '../../domain/entities/order.dart';
import 'base_api_service.dart';

class OrderApiDataSource extends BaseApiService {
  Future<Order?> createOrder({
    required DateTime withdrawDay,
    required List<int> itemIds,
    required List<int> supplierIds,
    required String status,
  }) async {
    final response = await post(
      '/orders',
      data: {
        'withdrawDay': withdrawDay.toIso8601String(),
        'itemIds': itemIds,
        'supplierIds': supplierIds,
        'status': status,
      },
    );
    if (response.statusCode == 200) {
      return Order.fromJson(response.data);
    }
    return null;
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
    int? createdById,
    int? lastUserId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (orderId != null) queryParameters['orderId'] = orderId;
    if (status != null && status.isNotEmpty) queryParameters['status'] = status;
    if (createdById != null) queryParameters['createdById'] = createdById;
    if (lastUserId != null) queryParameters['lastUserId'] = lastUserId;
    final response = await get(
      '/orders',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => Order.fromJson(e)).toList();
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
