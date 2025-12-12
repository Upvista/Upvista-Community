import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Secure token storage service
///
/// Uses Flutter Secure Storage to securely store JWT tokens
/// and user data. This ensures tokens are encrypted at rest.
class TokenStorageService {
  static final TokenStorageService _instance = TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: ApiConfig.accessTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to save access token: $e');
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: ApiConfig.accessTokenKey);
    } catch (e) {
      throw Exception('Failed to read access token: $e');
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: ApiConfig.refreshTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to save refresh token: $e');
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: ApiConfig.refreshTokenKey);
    } catch (e) {
      throw Exception('Failed to read refresh token: $e');
    }
  }

  /// Save user data
  Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: ApiConfig.userDataKey, value: userData);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Get user data
  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: ApiConfig.userDataKey);
    } catch (e) {
      throw Exception('Failed to read user data: $e');
    }
  }

  /// Clear all tokens and user data
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _storage.delete(key: ApiConfig.accessTokenKey),
        _storage.delete(key: ApiConfig.refreshTokenKey),
        _storage.delete(key: ApiConfig.userDataKey),
      ]);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
