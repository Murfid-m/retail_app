class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String address;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    this.avatarUrl,
    this.isAdmin = false,
    this.isVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      avatarUrl: json['avatar_url'],
      isAdmin: json['is_admin'] ?? false,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
    bool? isAdmin,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
