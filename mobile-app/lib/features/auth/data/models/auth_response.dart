import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

/// Auth response model matching backend AuthResponse
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AuthResponse {
  @JsonKey(name: 'success')
  final bool success;
  @JsonKey(name: 'message')
  final String? message;
  @JsonKey(name: 'token')
  final String? token;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @JsonKey(name: 'user')
  final User? user;
  @JsonKey(name: 'user_id')
  final String? userId;

  const AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.expiresAt,
    this.user,
    this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

/// Username availability check response
@JsonSerializable()
class UsernameAvailabilityResponse {
  final bool success;
  final bool available;
  final String? message;

  const UsernameAvailabilityResponse({
    required this.success,
    required this.available,
    this.message,
  });

  factory UsernameAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$UsernameAvailabilityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UsernameAvailabilityResponseToJson(this);
}
