import 'package:flutter/foundation.dart';
import '../models/signup_state.dart';

/// Signup state provider
///
/// Manages the multi-step signup flow state
/// Uses ChangeNotifier for Provider integration
class SignupStateProvider extends ChangeNotifier {
  SignupState _state = SignupState();

  SignupState get state => _state;

  /// Update email
  void setEmail(String email) {
    _state = _state.copyWith(email: email);
    notifyListeners();
  }

  /// Update verification code
  void setVerificationCode(String code) {
    _state = _state.copyWith(verificationCode: code);
    notifyListeners();
  }

  /// Update username
  void setUsername(String username) {
    _state = _state.copyWith(username: username);
    notifyListeners();
  }

  /// Update display name
  void setDisplayName(String displayName) {
    _state = _state.copyWith(displayName: displayName);
    notifyListeners();
  }

  /// Update gender
  void setGender(String? gender) {
    _state = _state.copyWith(gender: gender);
    notifyListeners();
  }

  /// Update age
  void setAge(int? age) {
    _state = _state.copyWith(age: age);
    notifyListeners();
  }

  /// Update profile picture
  void setProfilePicture(dynamic picture) {
    _state = _state.copyWith(profilePicture: picture);
    notifyListeners();
  }

  /// Update profile picture URL (after upload)
  void setProfilePictureUrl(String? url) {
    _state = _state.copyWith(profilePictureUrl: url);
    notifyListeners();
  }

  /// Update bio
  void setBio(String? bio) {
    _state = _state.copyWith(bio: bio);
    notifyListeners();
  }

  /// Update password
  void setPassword(String password) {
    _state = _state.copyWith(password: password);
    notifyListeners();
  }

  /// Update user ID (from registration response)
  void setUserId(String userId) {
    _state = _state.copyWith(userId: userId);
    notifyListeners();
  }

  /// Set OAuth user flag
  void setOAuthUser(bool isOAuth, {String? provider}) {
    _state = _state.copyWith(isOAuthUser: isOAuth, oauthProvider: provider);
    notifyListeners();
  }

  /// Update multiple fields at once
  void updateState(SignupState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _state.clear();
    notifyListeners();
  }

  /// Check if signup is complete
  bool get isComplete => _state.isComplete;

  /// Check if account name step is complete
  bool get isAccountNameComplete => _state.isAccountNameComplete;
}
