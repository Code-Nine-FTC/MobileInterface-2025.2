class Item {
  final String? id;
  final String name;
  final String? description;
  final int quantity;
  final String? location;
  final String? sectionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.name,
    this.description,
    required this.quantity,
    this.location,
    this.sectionId,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      location: json['location'],
      sectionId: json['section_id']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'location': location,
      'section_id': sectionId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Item(id: $id, name: $name, description: $description, quantity: $quantity, location: $location, sectionId: $sectionId)';
  }
}
