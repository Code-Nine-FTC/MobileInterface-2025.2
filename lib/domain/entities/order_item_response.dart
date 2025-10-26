class OrderItemResponse {
  final int id; // id da relação (order_item)
  final int itemId; // id do item do catálogo
  final String name;
  final int quantity;
  final String? unit;

  OrderItemResponse({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    this.unit,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'] ?? 0,
      itemId: json['itemId'] ?? json['item_id'] ?? 0,
      name: json['name'] ?? json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
    );
  }
}
