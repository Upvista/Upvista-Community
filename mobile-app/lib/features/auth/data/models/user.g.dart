// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  displayName: json['display_name'] as String,
  age: (json['age'] as num?)?.toInt(),
  gender: json['gender'] as String?,
  genderCustom: json['gender_custom'] as String?,
  bio: json['bio'] as String?,
  location: json['location'] as String?,
  website: json['website'] as String?,
  profilePicture: json['profile_picture'] as String?,
  isEmailVerified: json['is_email_verified'] as bool,
  isActive: json['is_active'] as bool,
  isVerified: json['is_verified'] as bool,
  oauthProvider: json['oauth_provider'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  lastLoginAt: json['last_login_at'] == null
      ? null
      : DateTime.parse(json['last_login_at'] as String),
  postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
  projectsCount: (json['projects_count'] as num?)?.toInt() ?? 0,
  followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
  followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
  profilePrivacy: json['profile_privacy'] as String?,
  fieldVisibility: (json['field_visibility'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
  statVisibility: (json['stat_visibility'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
  story: json['story'] as String?,
  ambition: json['ambition'] as String?,
  socialLinks: (json['social_links'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String?),
  ),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'username': instance.username,
  'display_name': instance.displayName,
  'age': ?instance.age,
  'gender': ?instance.gender,
  'gender_custom': ?instance.genderCustom,
  'bio': ?instance.bio,
  'location': ?instance.location,
  'website': ?instance.website,
  'profile_picture': ?instance.profilePicture,
  'is_email_verified': instance.isEmailVerified,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'oauth_provider': ?instance.oauthProvider,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_login_at': ?instance.lastLoginAt?.toIso8601String(),
  'posts_count': instance.postsCount,
  'projects_count': instance.projectsCount,
  'followers_count': instance.followersCount,
  'following_count': instance.followingCount,
  'profile_privacy': ?instance.profilePrivacy,
  'field_visibility': ?instance.fieldVisibility,
  'stat_visibility': ?instance.statVisibility,
  'story': ?instance.story,
  'ambition': ?instance.ambition,
  'social_links': ?instance.socialLinks,
};
