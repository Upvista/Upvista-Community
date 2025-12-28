import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Auth state provider
///
/// Manages authentication state and current user
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  /// Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final response = await _authService.getCurrentUser();
        if (response.success && response.data != null) {
          _currentUser = response.data;
          _isAuthenticated = true;
        } else {
          // Token might be invalid, clear auth
          await logout();
        }
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set current user
  void setUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Clear user (logout)
  /// Clears tokens, blacklists session, and resets auth state
  /// Optimized for speed - clears state immediately, API call in background
  Future<void> logout() async {
    // Clear auth state immediately (for instant UI response)
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();

    // Call logout API in background (don't block - speed optimization)
    _authService
        .logout()
        .then((_) {
          // Success - state already cleared
        })
        .catchError((_) {
          // Ignore errors - state is already cleared, user can proceed
        });
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _isAuthenticated = true;
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
