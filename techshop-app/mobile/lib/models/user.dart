class User {
  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'USER',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
