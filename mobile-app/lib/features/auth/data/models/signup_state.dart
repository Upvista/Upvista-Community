import 'dart:io';

/// Signup state model to store multi-step registration data
class SignupState {
  String? email;
  String? verificationCode;
  String? username;
  String? displayName;
  String? gender;
  int? age;
  File? profilePicture;
  String? profilePictureUrl; // After upload
  String? bio;
  String? password;
  String? userId; // From registration response
  bool isOAuthUser;
  String? oauthProvider;

  SignupState({
    this.email,
    this.verificationCode,
    this.username,
    this.displayName,
    this.gender,
    this.age,
    this.profilePicture,
    this.profilePictureUrl,
    this.bio,
    this.password,
    this.userId,
    this.isOAuthUser = false,
    this.oauthProvider,
  });

  /// Check if all required fields for registration are filled
  bool get isComplete {
    return email != null &&
        email!.isNotEmpty &&
        username != null &&
        username!.isNotEmpty &&
        displayName != null &&
        displayName!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty;
  }

  /// Check if account name step is complete
  bool get isAccountNameComplete {
    return username != null &&
        username!.isNotEmpty &&
        displayName != null &&
        displayName!.isNotEmpty;
  }

  /// Create a copy with updated fields
  SignupState copyWith({
    String? email,
    String? verificationCode,
    String? username,
    String? displayName,
    String? gender,
    int? age,
    File? profilePicture,
    String? profilePictureUrl,
    String? bio,
    String? password,
    String? userId,
    bool? isOAuthUser,
    String? oauthProvider,
  }) {
    return SignupState(
      email: email ?? this.email,
      verificationCode: verificationCode ?? this.verificationCode,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      password: password ?? this.password,
      userId: userId ?? this.userId,
      isOAuthUser: isOAuthUser ?? this.isOAuthUser,
      oauthProvider: oauthProvider ?? this.oauthProvider,
    );
  }

  /// Clear all data
  void clear() {
    email = null;
    verificationCode = null;
    username = null;
    displayName = null;
    gender = null;
    age = null;
    profilePicture = null;
    profilePictureUrl = null;
    bio = null;
    password = null;
    userId = null;
    isOAuthUser = false;
    oauthProvider = null;
  }

  /// Convert to JSON for backend registration
  Map<String, dynamic> toRegistrationJson() {
    return {
      'email': email,
      'password': password,
      'username': username,
      'display_name': displayName,
      if (age != null) 'age': age,
      if (gender != null) 'gender': _normalizeGender(gender),
      if (bio != null && bio!.isNotEmpty) 'bio': bio,
      if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty)
        'profile_picture': profilePictureUrl,
      if (verificationCode != null && verificationCode!.isNotEmpty)
        'verification_code': verificationCode,
    };
  }

  /// Normalize gender value for backend
  String _normalizeGender(String? gender) {
    if (gender == null) return '';
    final normalized = gender.toLowerCase().trim();
    // Map Flutter UI values to backend values
    switch (normalized) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      case 'other':
        return 'non-binary';
      case 'prefer not to say':
        return 'prefer-not-to-say';
      default:
        return normalized.replaceAll(' ', '-');
    }
  }

  /// Convert to JSON for OAuth profile completion
  Map<String, dynamic> toOAuthCompletionJson() {
    return {
      'password': password,
      'username': username,
      'display_name': displayName,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (bio != null) 'bio': bio,
      if (profilePictureUrl != null) 'profile_picture': profilePictureUrl,
    };
  }
}
