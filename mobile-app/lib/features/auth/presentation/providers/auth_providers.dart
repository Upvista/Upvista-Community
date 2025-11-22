import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_api_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/token_storage_service.dart';
import '../../data/models/auth_models.dart';

/// Dio provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
});

/// API Service provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioProvider));
});

/// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authApiServiceProvider));
});

/// Token Storage provider
final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.token,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      token: token ?? this.token,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;

  AuthNotifier(this._repository, this._tokenStorage) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final user = await _repository.getCurrentUser(token);
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
        );
      } catch (e) {
        // Token invalid, remove it
        await _tokenStorage.removeToken();
      }
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.register(request);
      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(request);
      if (response.success && response.token != null) {
        await _tokenStorage.saveToken(response.token!);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: response.token,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyEmail(VerifyEmailRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.verifyEmail(request);
      if (response.success && response.token != null) {
        await _tokenStorage.saveToken(response.token!);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: response.token,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = state.token ?? await _tokenStorage.getToken();
      if (token != null) {
        await _repository.logout(token);
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _tokenStorage.removeToken();
      state = AuthState();
    }
    return true;
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.forgotPassword(email);
      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.resetPassword(token, newPassword);
      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});

