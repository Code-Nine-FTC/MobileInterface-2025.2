class ExpirySummaryModel {
  final int expiredCount;
  final int expiringSoonCount;

  ExpirySummaryModel({
    required this.expiredCount,
    required this.expiringSoonCount,
  });

  factory ExpirySummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpirySummaryModel(
      expiredCount: json['expiredCount'] ?? 0,
      expiringSoonCount: json['expiringSoonCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expiredCount': expiredCount,
      'expiringSoonCount': expiringSoonCount,
    };
  }
}