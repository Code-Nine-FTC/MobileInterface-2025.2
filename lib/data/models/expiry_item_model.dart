class ExpiryItemModel {
  final int id;
  final String name;
  final double currentStock;
  final String measure;
  final DateTime? expireDate;
  final int sectionId;
  final String sectionTitle;
  final int itemTypeId;
  final String itemTypeName;
  final double minimumStock;
  final String? qrCode;
  final String lastUserName;
  final DateTime lastUpdate;

  ExpiryItemModel({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.measure,
    this.expireDate,
    required this.sectionId,
    required this.sectionTitle,
    required this.itemTypeId,
    required this.itemTypeName,
    required this.minimumStock,
    this.qrCode,
    required this.lastUserName,
    required this.lastUpdate,
  });

  bool get isExpired {
    if (expireDate == null) return false;
    return expireDate!.isBefore(DateTime.now());
  }

  int get daysRemaining {
    if (expireDate == null) return 0;
    final difference = expireDate!.difference(DateTime.now());
    return difference.inDays;
  }

  factory ExpiryItemModel.fromJson(Map<String, dynamic> json) {
    return ExpiryItemModel(
      id: json['itemId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      measure: json['measure'] ?? 'unidade',
      expireDate: json['expireDate'] != null
          ? DateTime.parse(json['expireDate'])
          : null,
      sectionId: json['sectionId'] ?? 0,
      sectionTitle: json['sectionName'] ?? json['sectionTitle'] ?? '',
      itemTypeId: json['itemTypeId'] ?? 0,
      itemTypeName: json['itemTypeName'] ?? '',
      minimumStock: (json['minimumStock'] ?? 0).toDouble(),
      qrCode: json['qrCode'],
      lastUserName: json['lastUserName'] ?? '',
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'measure': measure,
      'expireDate': expireDate?.toIso8601String(),
      'sectionId': sectionId,
      'sectionTitle': sectionTitle,
      'itemTypeId': itemTypeId,
      'itemTypeName': itemTypeName,
      'minimumStock': minimumStock,
      'qrCode': qrCode,
      'lastUserName': lastUserName,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}
