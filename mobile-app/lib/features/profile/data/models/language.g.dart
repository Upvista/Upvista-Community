// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Language _$LanguageFromJson(Map<String, dynamic> json) => Language(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  languageName: json['language_name'] as String,
  proficiencyLevel: json['proficiency_level'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$LanguageToJson(Language instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'language_name': instance.languageName,
  'proficiency_level': instance.proficiencyLevel,
  'display_order': instance.displayOrder,
  'created_at': instance.createdAt.toIso8601String(),
};
