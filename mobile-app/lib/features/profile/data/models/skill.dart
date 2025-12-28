import 'package:json_annotation/json_annotation.dart';

part 'skill.g.dart';

@JsonSerializable()
class Skill {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'skill_name')
  final String skillName;
  @JsonKey(name: 'proficiency_level')
  final String? proficiencyLevel; // beginner, intermediate, advanced, expert
  final String? category; // technical, soft, language, etc.
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.userId,
    required this.skillName,
    this.proficiencyLevel,
    this.category,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
  Map<String, dynamic> toJson() => _$SkillToJson(this);
}
