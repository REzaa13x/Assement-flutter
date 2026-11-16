class AuthResponse {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
  final String? tokenType;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.tokenType,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Token hadir berarti login/register berhasil
    final token = json['token'] as String?;
    final hasToken = token != null && token.isNotEmpty;

    // Beberapa backend mengirim field 'success' secara eksplisit
    final bool explicitSuccess = json['success'] == true;

    return AuthResponse(
      success: hasToken || explicitSuccess,
      message: json['message'] as String?,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: token,
      tokenType: json['token_type'] as String?,
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
    );
  }
}

class ProfileResponse {
  final String? message;
  final UserProfile? data;

  ProfileResponse({
    this.message,
    this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      message: json['message'],
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }
}

class User {
  final int? id;
  final String name;
  final String email;
  final String? role;
  final int? coins;
  final String? photo;
  final String? phone;
  final String? birthDate;
  final String? address;  // Menambahkan field address (alamat domisili)
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.coins,
    this.photo,
    this.phone,
    this.birthDate,
    this.address,  // Menambahkan parameter address
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['user_role'],
      coins: json['coins'] ?? json['coin_balance']?.toInt() ?? 0,
      photo: json['photo'] ?? json['profile_photo'],
      phone: json['phone'] ?? json['phone_number'],
      birthDate: json['birth_date'] ?? json['tanggal_lahir'],
      address: json['address'] ?? json['domisili'] ?? json['alamat'],  // Menambahkan mapping untuk address
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'coins': coins,
      'photo': photo,
      'phone': phone,
      'birth_date': birthDate,
      'address': address,  // Menambahkan field address
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class UserProfile {
  final int? id;
  final String name;
  final String email;
  final String? role;
  final int? coins;
  final String? photo;
  final String? phone;
  final String? birthDate;
  final String? address;  // Menambahkan field address (alamat domisili)
  final String? createdAt;
  final String? updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.coins,
    this.photo,
    this.phone,
    this.birthDate,
    this.address,  // Menambahkan parameter address
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['user_role'],
      coins: json['coins'] ?? json['coin_balance']?.toInt() ?? 0,
      photo: json['photo'] ?? json['profile_photo'],
      phone: json['phone'] ?? json['phone_number'],
      birthDate: json['birth_date'] ?? json['tanggal_lahir'],
      address: json['address'] ?? json['domisili'] ?? json['alamat'],  // Menambahkan mapping untuk address
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'coins': coins,
      'photo': photo,
      'phone': phone,
      'birth_date': birthDate,
      'address': address,  // Menambahkan field address
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}