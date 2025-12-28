import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// User model matching backend User structure
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class User {
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'email')
  final String email;
  @JsonKey(name: 'username')
  final String username;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'age')
  final int? age;
  @JsonKey(name: 'gender')
  final String? gender;
  @JsonKey(name: 'gender_custom')
  final String? genderCustom;
  @JsonKey(name: 'bio')
  final String? bio;
  @JsonKey(name: 'location')
  final String? location;
  @JsonKey(name: 'website')
  final String? website;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  @JsonKey(name: 'is_email_verified')
  final bool isEmailVerified;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'oauth_provider')
  final String? oauthProvider;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;

  // Profile stats
  @JsonKey(name: 'posts_count')
  final int postsCount;
  @JsonKey(name: 'projects_count')
  final int projectsCount;
  @JsonKey(name: 'followers_count')
  final int followersCount;
  @JsonKey(name: 'following_count')
  final int followingCount;

  // Privacy settings
  @JsonKey(name: 'profile_privacy')
  final String? profilePrivacy;
  @JsonKey(name: 'field_visibility')
  final Map<String, bool>? fieldVisibility;
  @JsonKey(name: 'stat_visibility')
  final Map<String, bool>? statVisibility;

  // Additional profile fields
  @JsonKey(name: 'story')
  final String? story;
  @JsonKey(name: 'ambition')
  final String? ambition;
  @JsonKey(name: 'social_links')
  final Map<String, String?>? socialLinks;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.age,
    this.gender,
    this.genderCustom,
    this.bio,
    this.location,
    this.website,
    this.profilePicture,
    required this.isEmailVerified,
    required this.isActive,
    required this.isVerified,
    this.oauthProvider,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.postsCount = 0,
    this.projectsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.profilePrivacy,
    this.fieldVisibility,
    this.statVisibility,
    this.story,
    this.ambition,
    this.socialLinks,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    int? age,
    String? gender,
    String? genderCustom,
    String? bio,
    String? location,
    String? website,
    String? profilePicture,
    bool? isEmailVerified,
    bool? isActive,
    bool? isVerified,
    String? oauthProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? postsCount,
    int? projectsCount,
    int? followersCount,
    int? followingCount,
    String? profilePrivacy,
    Map<String, bool>? fieldVisibility,
    Map<String, bool>? statVisibility,
    String? story,
    String? ambition,
    Map<String, String?>? socialLinks,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      genderCustom: genderCustom ?? this.genderCustom,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      profilePicture: profilePicture ?? this.profilePicture,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      postsCount: postsCount ?? this.postsCount,
      projectsCount: projectsCount ?? this.projectsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      profilePrivacy: profilePrivacy ?? this.profilePrivacy,
      fieldVisibility: fieldVisibility ?? this.fieldVisibility,
      statVisibility: statVisibility ?? this.statVisibility,
      story: story ?? this.story,
      ambition: ambition ?? this.ambition,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
