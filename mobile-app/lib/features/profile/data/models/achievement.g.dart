// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  achievementType: json['achievement_type'] as String?,
  issuingOrganization: json['issuing_organization'] as String?,
  achievementDate: json['achievement_date'] == null
      ? null
      : DateTime.parse(json['achievement_date'] as String),
  description: json['description'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'achievement_type': instance.achievementType,
      'issuing_organization': instance.issuingOrganization,
      'achievement_date': instance.achievementDate?.toIso8601String(),
      'description': instance.description,
      'display_order': instance.displayOrder,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
