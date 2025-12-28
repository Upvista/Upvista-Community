import 'package:json_annotation/json_annotation.dart';

part 'publication.g.dart';

@JsonSerializable()
class Publication {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  @JsonKey(name: 'publication_type')
  final String? publicationType; // article, book, paper, blog, etc.
  final String? publisher;
  @JsonKey(name: 'publication_date')
  final DateTime? publicationDate;
  @JsonKey(name: 'publication_url')
  final String? publicationUrl;
  final String? description;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Publication({
    required this.id,
    required this.userId,
    required this.title,
    this.publicationType,
    this.publisher,
    this.publicationDate,
    this.publicationUrl,
    this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Publication.fromJson(Map<String, dynamic> json) =>
      _$PublicationFromJson(json);
  Map<String, dynamic> toJson() => _$PublicationToJson(this);
}
