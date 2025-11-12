class UserInfo {
  final int id;
  final String name;
  final String email;
  final String userType; // 'USER' ou 'GUEST'
  final String? chatRoomId; // Apenas para GUEST
  final String? role; // Para USER: 'ADMIN', 'MANAGER', 'ASSISTANT'
  final String? sessionId; // Para USER

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.chatRoomId,
    this.role,
    this.sessionId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? 'USER',
      chatRoomId: json['chatRoomId']?.toString(),
      role: json['role']?.toString(),
      sessionId: json['sessionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'chatRoomId': chatRoomId,
      'role': role,
      'sessionId': sessionId,
    };
  }

  bool get isGuest => userType == 'GUEST';
  bool get isUser => userType == 'USER';
}
