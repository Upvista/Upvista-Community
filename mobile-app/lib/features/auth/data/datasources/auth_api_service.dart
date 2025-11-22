import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../models/auth_models.dart';

/// Authentication API Service
/// Handles all authentication API calls

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  /// Register a new user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify email with code
  Future<AuthResponse> verifyEmail(VerifyEmailRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/verify-email',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request password reset
  Future<AuthResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/forgot-password',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset password with token
  Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/reset-password',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout user
  Future<AuthResponse> logout(String token) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/auth/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user info
  Future<User> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return User.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'An error occurred';
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Failed to connect to server. Please check if backend is running.';
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

