class User {
  final String id;
  final String name;
  final String email;
  final String? sessionId;

  User({required this.id, required this.name, required this.email, this.sessionId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      sessionId: json['sessionId'],
    );
  }

  Map<String, String?> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'sessionId': sessionId,
    };
  }
}