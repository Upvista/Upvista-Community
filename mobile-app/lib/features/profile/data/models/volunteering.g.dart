// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volunteering.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Volunteering _$VolunteeringFromJson(Map<String, dynamic> json) => Volunteering(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  organizationName: json['organization_name'] as String,
  role: json['role'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  isCurrent: json['is_current'] as bool,
  description: json['description'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$VolunteeringToJson(Volunteering instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'organization_name': instance.organizationName,
      'role': instance.role,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'is_current': instance.isCurrent,
      'description': instance.description,
      'display_order': instance.displayOrder,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
