import 'package:json_annotation/json_annotation.dart';

part 'language.g.dart';

@JsonSerializable()
class Language {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'language_name')
  final String languageName;
  @JsonKey(name: 'proficiency_level')
  final String? proficiencyLevel; // basic, conversational, fluent, native
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Language({
    required this.id,
    required this.userId,
    required this.languageName,
    this.proficiencyLevel,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageToJson(this);
}
