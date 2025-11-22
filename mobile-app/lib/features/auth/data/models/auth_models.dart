/// Authentication data models
/// Matching backend API request/response formats

class RegisterRequest {
  final String email;
  final String password;
  final String displayName;
  final String username;
  final int age;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.displayName,
    required this.username,
    required this.age,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'display_name': displayName,
        'username': username,
        'age': age,
      };
}

class LoginRequest {
  final String emailOrUsername;
  final String password;

  LoginRequest({
    required this.emailOrUsername,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email_or_username': emailOrUsername,
        'password': password,
      };
}

class VerifyEmailRequest {
  final String email;
  final String verificationCode;

  VerifyEmailRequest({
    required this.email,
    required this.verificationCode,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'verification_code': verificationCode,
      };
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}

class ResetPasswordRequest {
  final String token;
  final String newPassword;

  ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'new_password': newPassword,
      };
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final DateTime? expiresAt;
  final User? user;
  final String? userId;
  final String? error;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.expiresAt,
    this.user,
    this.userId,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        token: json['token'],
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'])
            : null,
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        userId: json['user_id'],
        error: json['error'],
      );
}

class User {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final int? age;
  final bool isEmailVerified;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? profilePicture;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.age,
    required this.isEmailVerified,
    this.isActive,
    this.createdAt,
    this.lastLoginAt,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? '',
        displayName: json['display_name'] ?? '',
        age: json['age'],
        isEmailVerified: json['is_email_verified'] ?? false,
        isActive: json['is_active'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'])
            : null,
        profilePicture: json['profile_picture'],
      );
}
