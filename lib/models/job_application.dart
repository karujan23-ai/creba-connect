import 'enums.dart';
import 'model_utils.dart';

/// A creator's application to a hiring post, stored at
/// `applications/{jobId_creatorId}`.
///
/// Building the document ID from the job and the creator means one creator
/// can only ever have one application per job.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.creatorId,
    required this.brandId,
    required this.jobTitle,
    required this.creatorName,
    required this.brandName,
    this.message = '',
    this.proposedRate,
    this.status = ApplicationStatus.applied,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String creatorId;
  final String brandId;
  final String jobTitle;
  final String creatorName;
  final String brandName;
  final String message;

  /// The creator's asking price in NPR, if they gave one.
  final num? proposedRate;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String idFor(String jobId, String creatorId) => '${jobId}_$creatorId';

  /// The creator may withdraw only while the brand has not decided.
  bool get canWithdraw =>
      status == ApplicationStatus.applied ||
      status == ApplicationStatus.shortlisted ||
      status == ApplicationStatus.discussion;

  factory JobApplication.fromJson(Map<String, dynamic> json, String id) =>
      JobApplication(
        id: id,
        jobId: readString(json['jobId']),
        creatorId: readString(json['creatorId']),
        brandId: readString(json['brandId']),
        jobTitle: readString(json['jobTitle']),
        creatorName: readString(json['creatorName']),
        brandName: readString(json['brandName']),
        message: readString(json['message']),
        proposedRate:
            json['proposedRate'] is num ? json['proposedRate'] as num : null,
        status: ApplicationStatus.fromValue(json['status'] as String?),
        createdAt: readDateOrNow(json['createdAt']),
        updatedAt: readDateOrNow(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'creatorId': creatorId,
        'brandId': brandId,
        'jobTitle': jobTitle,
        'creatorName': creatorName,
        'brandName': brandName,
        'message': message,
        'proposedRate': proposedRate,
        'status': status.value,
        'createdAt': writeDate(createdAt),
        'updatedAt': writeDate(updatedAt),
      };
}
