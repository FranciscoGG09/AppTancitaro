class User {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Constructor desde JSON (API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convertir a JSON para API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Obtener nombre completo
  String get fullName {
    if (firstName == null && lastName == null) return 'Usuario';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  // Verificar si el perfil está completo
  bool get isProfileComplete {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        phone.isNotEmpty;
  }

  // Obtener iniciales para avatar
  String get initials {
    if (firstName == null || lastName == null) return 'U';

    final firstInitial = firstName!.isNotEmpty ? firstName![0] : '';
    final lastInitial = lastName!.isNotEmpty ? lastName![0] : '';

    return '${firstInitial}${lastInitial}'.toUpperCase();
  }

  // Clonar usuario con nuevos valores
  User copyWith({
    String? id,
    String? phone,
    String? firstName,
    String? lastName,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
