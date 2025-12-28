import 'package:json_annotation/json_annotation.dart';

part 'volunteering.g.dart';

@JsonSerializable()
class Volunteering {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'organization_name')
  final String organizationName;
  final String role;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'is_current')
  final bool isCurrent;
  final String? description;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Volunteering({
    required this.id,
    required this.userId,
    required this.organizationName,
    required this.role,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Volunteering.fromJson(Map<String, dynamic> json) =>
      _$VolunteeringFromJson(json);
  Map<String, dynamic> toJson() => _$VolunteeringToJson(this);
}
