import 'package:json_annotation/json_annotation.dart';

part 'achievement.g.dart';

@JsonSerializable()
class Achievement {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  @JsonKey(name: 'achievement_type')
  final String? achievementType; // award, recognition, milestone, etc.
  @JsonKey(name: 'issuing_organization')
  final String? issuingOrganization;
  @JsonKey(name: 'achievement_date')
  final DateTime? achievementDate;
  final String? description;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.achievementType,
    this.issuingOrganization,
    this.achievementDate,
    this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}
