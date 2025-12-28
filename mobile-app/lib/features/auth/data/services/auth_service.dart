import '../../../../core/api/api_client.dart';
import '../../../../core/api/models/api_response.dart';
import '../../../../core/api/exceptions/api_exception.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/token_storage_service.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../models/signup_state.dart';

/// Authentication service
///
/// Handles all authentication-related API calls including:
/// - Registration
/// - Email verification
/// - Login
/// - Username availability check
/// - OAuth flows
/// - Token management
class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Register a new user
  ///
  /// Sends all collected signup data to backend
  Future<ApiResponse<AuthResponse>> register(SignupState state) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/register',
        data: state.toRegistrationJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final authResponse = AuthResponse.fromJson(response);

      // Store token if registration successful and token is provided
      if (authResponse.success && authResponse.token != null) {
        await _tokenStorage.saveAccessToken(authResponse.token!);
        if (authResponse.user != null) {
          await _tokenStorage.saveUserData(
            authResponse.user!.toJson().toString(),
          );
        }
      }

      return ApiResponse<AuthResponse>(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse,
      );
    } catch (e, stackTrace) {
      // Log the full error for debugging
      print('Registration error: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse<AuthResponse>(
        success: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Verify email with OTP code
  Future<ApiResponse<AuthResponse>> verifyEmail(
    String email,
    String verificationCode,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/verify-email',
        data: {'email': email, 'verification_code': verificationCode},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final authResponse = AuthResponse.fromJson(response);

      // Store token if verification successful
      if (authResponse.success && authResponse.token != null) {
        await _tokenStorage.saveAccessToken(authResponse.token!);
        if (authResponse.user != null) {
          await _tokenStorage.saveUserData(
            authResponse.user!.toJson().toString(),
          );
        }
      }

      return ApiResponse<AuthResponse>(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(success: false, error: e.toString());
    }
  }

  /// Send OTP for signup (before registration)
  Future<ApiResponse<void>> sendSignupOTP(String email) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/send-signup-otp',
        data: {'email': email},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return ApiResponse<void>(
        success: response['success'] as bool? ?? false,
        message: response['message'] as String?,
      );
    } catch (e) {
      return ApiResponse<void>(success: false, error: e.toString());
    }
  }

  /// Verify OTP for signup (before registration)
  Future<ApiResponse<void>> verifySignupOTP(String email, String code) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/verify-signup-otp',
        data: {'email': email, 'code': code},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return ApiResponse<void>(
        success: response['success'] as bool? ?? false,
        message: response['message'] as String?,
      );
    } on ApiException catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Invalid verification code. Please try again.';

      if (e is ValidationException) {
        errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Invalid verification code. Please check and try again.';
      } else if (e is ServerException) {
        errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Verification failed. Please try again.';
      } else if (e.message.isNotEmpty) {
        errorMessage = e.message;
      }

      return ApiResponse<void>(
        success: false,
        error: errorMessage,
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: 'Verification failed. Please check your code and try again.',
      );
    }
  }

  /// Check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.auth}/check-username',
        queryParameters: {'username': username},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final availabilityResponse = UsernameAvailabilityResponse.fromJson(
        response,
      );
      return availabilityResponse.available;
    } catch (e) {
      // On error, assume unavailable to be safe
      return false;
    }
  }

  /// Login with email/username and password
  Future<ApiResponse<AuthResponse>> login(
    String emailOrUsername,
    String password,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/login',
        data: {'email_or_username': emailOrUsername, 'password': password},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final authResponse = AuthResponse.fromJson(response);

      // Store token if login successful
      if (authResponse.success && authResponse.token != null) {
        await _tokenStorage.saveAccessToken(authResponse.token!);
        if (authResponse.user != null) {
          await _tokenStorage.saveUserData(
            authResponse.user!.toJson().toString(),
          );
        }
      }

      return ApiResponse<AuthResponse>(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse,
      );
    } catch (e) {
      // Provide more helpful error messages
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('timeout') ||
          errorMessage.toLowerCase().contains('connection')) {
        errorMessage =
            'Cannot connect to server at ${ApiConfig.baseUrl}.\n'
            'Please verify:\n'
            '• Backend server is running on port 8081\n'
            '• For Android emulator, use 10.0.2.2 instead of IP\n'
            '• For physical device, ensure same network\n'
            '• Check firewall settings';
      } else if (errorMessage.toLowerCase().contains('401') ||
          errorMessage.toLowerCase().contains('authentication') ||
          errorMessage.toLowerCase().contains('invalid')) {
        errorMessage = 'Invalid email or password. Please try again.';
      }
      return ApiResponse<AuthResponse>(success: false, error: errorMessage);
    }
  }

  /// Get OAuth authorization URL
  Future<String> getOAuthUrl(String provider) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.auth}/$provider/login',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response['auth_url'] as String? ?? '';
    } catch (e) {
      throw Exception('Failed to get OAuth URL: $e');
    }
  }

  /// Exchange OAuth code for token
  Future<ApiResponse<AuthResponse>> exchangeOAuthCode(
    String provider,
    String code,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.auth}/$provider/exchange',
        data: {'code': code},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final authResponse = AuthResponse.fromJson(response);

      // Store token if exchange successful
      if (authResponse.success && authResponse.token != null) {
        await _tokenStorage.saveAccessToken(authResponse.token!);
        if (authResponse.user != null) {
          await _tokenStorage.saveUserData(
            authResponse.user!.toJson().toString(),
          );
        }
      }

      return ApiResponse<AuthResponse>(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(success: false, error: e.toString());
    }
  }

  /// Complete OAuth profile with additional required information
  Future<ApiResponse<AuthResponse>> completeOAuthProfile(
    SignupState state,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/oauth/complete-profile',
        data: state.toOAuthCompletionJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final authResponse = AuthResponse.fromJson(response);

      // Update token if profile completion successful
      if (authResponse.success && authResponse.token != null) {
        await _tokenStorage.saveAccessToken(authResponse.token!);
        if (authResponse.user != null) {
          await _tokenStorage.saveUserData(
            authResponse.user!.toJson().toString(),
          );
        }
      }

      return ApiResponse<AuthResponse>(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(success: false, error: e.toString());
    }
  }

  /// Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.auth + '/me',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final userResponse = response['user'] as Map<String, dynamic>?;
      if (userResponse != null) {
        final user = User.fromJson(userResponse);
        return ApiResponse<User>(success: true, data: user);
      }

      return ApiResponse<User>(success: false, error: 'User data not found');
    } catch (e) {
      return ApiResponse<User>(success: false, error: e.toString());
    }
  }

  /// Logout current user
  /// Clears tokens, blacklists session on server, and returns success status
  Future<ApiResponse<void>> logout() async {
    try {
      // Call backend logout endpoint to blacklist token
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.auth + '/logout',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Clear local tokens and user data regardless of response
      await _tokenStorage.clearAll();

      return ApiResponse<void>(
        success: response['success'] as bool? ?? true,
        message: response['message'] as String?,
      );
    } catch (e) {
      // Even if backend call fails, clear local data
      await _tokenStorage.clearAll();

      // Return success to allow logout to proceed
      return ApiResponse<void>(
        success: true,
        message: 'Logged out successfully',
      );
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.isLoggedIn();
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }
}
