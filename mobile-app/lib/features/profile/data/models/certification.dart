import 'package:json_annotation/json_annotation.dart';

part 'certification.g.dart';

@JsonSerializable()
class Certification {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  @JsonKey(name: 'issuing_organization')
  final String? issuingOrganization;
  @JsonKey(name: 'issue_date')
  final DateTime issueDate;
  @JsonKey(name: 'expiration_date')
  final DateTime? expirationDate;
  @JsonKey(name: 'credential_id')
  final String? credentialId;
  @JsonKey(name: 'credential_url')
  final String? credentialUrl;
  final String? description;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Certification({
    required this.id,
    required this.userId,
    required this.name,
    this.issuingOrganization,
    required this.issueDate,
    this.expirationDate,
    this.credentialId,
    this.credentialUrl,
    this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certification.fromJson(Map<String, dynamic> json) =>
      _$CertificationFromJson(json);
  Map<String, dynamic> toJson() => _$CertificationToJson(this);
}
