// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Publication _$PublicationFromJson(Map<String, dynamic> json) => Publication(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  publicationType: json['publication_type'] as String?,
  publisher: json['publisher'] as String?,
  publicationDate: json['publication_date'] == null
      ? null
      : DateTime.parse(json['publication_date'] as String),
  publicationUrl: json['publication_url'] as String?,
  description: json['description'] as String?,
  displayOrder: (json['display_order'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PublicationToJson(Publication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'publication_type': instance.publicationType,
      'publisher': instance.publisher,
      'publication_date': instance.publicationDate?.toIso8601String(),
      'publication_url': instance.publicationUrl,
      'description': instance.description,
      'display_order': instance.displayOrder,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
