class Lot {
  final int id;
  final int itemId;
  final String itemName;
  final String code;
  final String? expireDate; // yyyy-MM-dd or null
  final int quantityOnHand;

  Lot({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.code,
    required this.expireDate,
    required this.quantityOnHand,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Lot(
      id: parseInt(json['id']),
      itemId: parseInt(json['itemId'] ?? json['item_id']),
      itemName: json['itemName']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      expireDate: json['expireDate']?.toString(),
      quantityOnHand: parseInt(json['quantityOnHand'] ?? json['quantity_on_hand']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'code': code,
        'expireDate': expireDate,
        'quantityOnHand': quantityOnHand,
      };
}
