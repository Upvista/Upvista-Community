import '../datasources/auth_api_service.dart';
import '../models/auth_models.dart';

/// Authentication Repository
/// Business logic layer for authentication

class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository(this._apiService);

  Future<AuthResponse> register(RegisterRequest request) async {
    return await _apiService.register(request);
  }

  Future<AuthResponse> login(LoginRequest request) async {
    return await _apiService.login(request);
  }

  Future<AuthResponse> verifyEmail(VerifyEmailRequest request) async {
    return await _apiService.verifyEmail(request);
  }

  Future<AuthResponse> forgotPassword(String email) async {
    return await _apiService.forgotPassword(ForgotPasswordRequest(email: email));
  }

  Future<AuthResponse> resetPassword(String token, String newPassword) async {
    return await _apiService.resetPassword(
      ResetPasswordRequest(token: token, newPassword: newPassword),
    );
  }

  Future<AuthResponse> logout(String token) async {
    return await _apiService.logout(token);
  }

  Future<User> getCurrentUser(String token) async {
    return await _apiService.getCurrentUser(token);
  }
}

