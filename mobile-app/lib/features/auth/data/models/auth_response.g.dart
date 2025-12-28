// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  token: json['token'] as String?,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': ?instance.message,
      'token': ?instance.token,
      'expires_at': ?instance.expiresAt?.toIso8601String(),
      'user': ?instance.user?.toJson(),
      'user_id': ?instance.userId,
    };

UsernameAvailabilityResponse _$UsernameAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => UsernameAvailabilityResponse(
  success: json['success'] as bool,
  available: json['available'] as bool,
  message: json['message'] as String?,
);

Map<String, dynamic> _$UsernameAvailabilityResponseToJson(
  UsernameAvailabilityResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'available': instance.available,
  'message': instance.message,
};
