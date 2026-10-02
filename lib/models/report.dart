import 'enums.dart';
import 'model_utils.dart';

/// A user's report about a profile or post, stored at `reports/{id}`.
class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.targetLabel,
    required this.reason,
    this.description = '',
    this.status = ReportStatus.open,
    required this.createdAt,
    this.resolvedBy,
    this.resolvedAt,
  });

  final String id;
  final String reporterId;
  final String targetId;
  final TargetType targetType;

  /// Name or title of the reported item, so admins can read the list quickly.
  final String targetLabel;
  final String reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  factory Report.fromJson(Map<String, dynamic> json, String id) => Report(
        id: id,
        reporterId: readString(json['reporterId']),
        targetId: readString(json['targetId']),
        targetType: TargetType.fromValue(json['targetType'] as String?),
        targetLabel: readString(json['targetLabel']),
        reason: readString(json['reason']),
        description: readString(json['description']),
        status: ReportStatus.fromValue(json['status'] as String?),
        createdAt: readDateOrNow(json['createdAt']),
        resolvedBy: readOptionalString(json['resolvedBy']),
        resolvedAt: readDate(json['resolvedAt']),
      );

  Map<String, dynamic> toJson() => {
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType.value,
        'targetLabel': targetLabel,
        'reason': reason,
        'description': description,
        'status': status.value,
        'createdAt': writeDate(createdAt),
        'resolvedBy': resolvedBy,
        'resolvedAt': writeDate(resolvedAt),
      };
}
