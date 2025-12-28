// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Interest _$InterestFromJson(Map<String, dynamic> json) => Interest(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  interestName: json['interest_name'] as String,
  category: json['category'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InterestToJson(Interest instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'interest_name': instance.interestName,
  'category': instance.category,
  'display_order': instance.displayOrder,
  'created_at': instance.createdAt.toIso8601String(),
};
