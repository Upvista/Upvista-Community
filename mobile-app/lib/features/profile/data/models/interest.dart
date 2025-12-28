import 'package:json_annotation/json_annotation.dart';

part 'interest.g.dart';

@JsonSerializable()
class Interest {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'interest_name')
  final String interestName;
  final String? category; // hobby, professional, academic, etc.
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Interest({
    required this.id,
    required this.userId,
    required this.interestName,
    this.category,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Interest.fromJson(Map<String, dynamic> json) =>
      _$InterestFromJson(json);
  Map<String, dynamic> toJson() => _$InterestToJson(this);
}
