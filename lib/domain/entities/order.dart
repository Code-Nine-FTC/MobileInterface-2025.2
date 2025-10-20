import 'package:meta/meta.dart';

class Order {
  final int id;
  final DateTime withdrawDay;
  final String status;
  final DateTime createdAt;
  final DateTime lastDay;
  final DateTime lastUpdate;
  final int? createdById;
  final int? lastUserId;
  final List<int> itemIds;
  final DateTime? completionDate;

  Order({
    required this.id,
    required this.withdrawDay,
    required this.status,
    required this.createdAt,
    required this.lastDay,
    required this.lastUpdate,
    this.createdById,
    this.lastUserId,
    required this.itemIds,
    this.completionDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('Order.fromJson recebido:');
    print(json);
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }
    // Helper para garantir lista
    List ensureList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      return [value];
    }
    return Order(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      withdrawDay: json['withdrawDay'] != null ? DateTime.tryParse(json['withdrawDay'].toString()) ?? DateTime(2000) : DateTime(2000),
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime(2000) : DateTime(2000),
      lastDay: json['lastDay'] != null ? DateTime.tryParse(json['lastDay'].toString()) ?? DateTime(2000) : DateTime(2000),
      lastUpdate: json['lastUpdate'] != null ? DateTime.tryParse(json['lastUpdate'].toString()) ?? DateTime(2000) : DateTime(2000),
      createdById: parseId(json['createdBy']?['id']) ?? parseId(json['created_by_id']),
      lastUserId: parseId(json['lastUser']?['id']) ?? parseId(json['last_user_id']),
      itemIds: ensureList(json['items']).map<int>((e) {
        final id = e['itemId'] ?? e['id'];
        if (id == null) return 0;
        if (id is int) return id;
        return int.tryParse(id.toString()) ?? 0;
      }).toList(),
      completionDate: json['completionDate'] != null ? DateTime.tryParse(json['completionDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'withdrawDay': withdrawDay.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'lastDay': lastDay.toIso8601String(),
        'lastUpdate': lastUpdate.toIso8601String(),
        'createdById': createdById,
        'lastUserId': lastUserId,
        'itemIds': itemIds,
        'completionDate': completionDate?.toIso8601String(),
      };
}
