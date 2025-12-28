// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Certification _$CertificationFromJson(Map<String, dynamic> json) =>
    Certification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      issuingOrganization: json['issuing_organization'] as String?,
      issueDate: DateTime.parse(json['issue_date'] as String),
      expirationDate: json['expiration_date'] == null
          ? null
          : DateTime.parse(json['expiration_date'] as String),
      credentialId: json['credential_id'] as String?,
      credentialUrl: json['credential_url'] as String?,
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CertificationToJson(Certification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'issuing_organization': instance.issuingOrganization,
      'issue_date': instance.issueDate.toIso8601String(),
      'expiration_date': instance.expirationDate?.toIso8601String(),
      'credential_id': instance.credentialId,
      'credential_url': instance.credentialUrl,
      'description': instance.description,
      'display_order': instance.displayOrder,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
