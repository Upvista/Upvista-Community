// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Skill _$SkillFromJson(Map<String, dynamic> json) => Skill(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  skillName: json['skill_name'] as String,
  proficiencyLevel: json['proficiency_level'] as String?,
  category: json['category'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SkillToJson(Skill instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'skill_name': instance.skillName,
  'proficiency_level': instance.proficiencyLevel,
  'category': instance.category,
  'display_order': instance.displayOrder,
  'created_at': instance.createdAt.toIso8601String(),
};
