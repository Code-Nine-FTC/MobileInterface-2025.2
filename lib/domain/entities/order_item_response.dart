class OrderItemResponse {
  final int id;
  final String name;
  final int quantity;
  final String? unit;
  final String? supplierName;

  OrderItemResponse({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    this.supplierName,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'] ?? json['itemId'] ?? 0,
      name: json['name'] ?? json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
      supplierName: json['supplierName'],
    );
  }
}
