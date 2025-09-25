class User {
  final int id;
  final String name;
  final String email;
  String? sessionId;
  String? role;

  User({required this.id, required this.name, required this.email, this.sessionId, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id']),
      name: json['name']?? json['username'] ,
      email: json['email'],
      sessionId: json['sessionId'],
      role: json['role'],
    );
  }

  Map<String, String?> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'email': email,
      'sessionId': sessionId,
      'role': role,
    };
  }
}