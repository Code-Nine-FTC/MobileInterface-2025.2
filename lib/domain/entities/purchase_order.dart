class PurchaseOrder {
  final int id;
  final String? issuingBody; // órgão emissor
  final String? commitmentNoteNumber; // número da NE (Nota de Empenho)
  final int? year;
  final String? processNumber; // número do processo
  final int? orderId; // referência ao pedido, se houver
  final int? supplierCompanyId;
  final String? supplierCompanyTitle;
  final double? totalValue;
  final DateTime? issueDate;
  final String status;
  final String? emailStatus;
  final DateTime? createdAt;
  final int? createdById;
  final int? senderId;
  final String? senderName;

  PurchaseOrder({
    required this.id,
    this.issuingBody,
    this.commitmentNoteNumber,
    this.year,
    this.processNumber,
    this.orderId,
    this.supplierCompanyId,
    this.supplierCompanyTitle,
    this.totalValue,
    this.issueDate,
    required this.status,
    this.emailStatus,
    this.createdAt,
    this.createdById,
    this.senderId,
    this.senderName,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return PurchaseOrder(
      id: parseInt(json['id'] ?? json['purchaseOrderId'] ?? json['poId']),
      issuingBody: json['issuingBody']?.toString(),
      commitmentNoteNumber: json['commitmentNoteNumber']?.toString(),
      year: json['year'] != null ? parseInt(json['year']) : null,
      processNumber: json['processNumber']?.toString(),
      orderId: json['orderId'] != null ? parseInt(json['orderId']) : null,
      supplierCompanyId: json['supplierCompanyId'] != null ? parseInt(json['supplierCompanyId']) : null,
      supplierCompanyTitle: (json['supplierCompanyTitle'] ?? json['supplierCompanyName'] ?? json['supplierTitle'] ?? json['supplier']?['title'])?.toString(),
      totalValue: parseDouble(json['totalValue'] ?? json['total']),
      issueDate: parseDate(json['issueDate'] ?? json['emissionDate'] ?? json['issue_date']),
      status: json['status']?.toString() ?? json['situacao']?.toString() ?? '',
      emailStatus: json['emailStatus']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      createdById: json['createdBy']?['id'] != null ? parseInt(json['createdBy']?['id']) : null,
      senderId: json['senderId'] != null ? parseInt(json['senderId']) : (json['sender']?['id'] != null ? parseInt(json['sender']?['id']) : null),
      senderName: json['senderName']?.toString() ?? json['sender']?['name']?.toString(),
    );
  }
}
