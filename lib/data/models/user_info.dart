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
    // O backend pode retornar em dois formatos:
    // Formato 1 (aninhado): { userType: "USER", user: { id, name, email, role } }
    // Formato 2 (plano): { id, name, email, userType, role, chatRoomId }
    
    final userType = json['userType'] ?? 'USER';
    
    // Se tem campo 'user' aninhado, extrair dele
    final userData = json['user'] ?? json;
    
    int? id;
    if (userData['id'] != null) {
      id = userData['id'] is int ? userData['id'] : int.parse(userData['id'].toString());
    }
    
    return UserInfo(
      id: id ?? 0,
      name: userData['name']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      userType: userType,
      chatRoomId: json['chatRoomId']?.toString() ?? userData['chatRoomId']?.toString(),
      role: userData['role']?.toString(),
      sessionId: userData['sessionId']?.toString(),
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
