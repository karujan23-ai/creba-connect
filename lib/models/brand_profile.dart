import 'enums.dart';
import 'model_utils.dart';

/// A brand's public profile, stored at `brandProfiles/{uid}`.
class BrandProfile {
  const BrandProfile({
    required this.uid,
    required this.brandName,
    this.category = '',
    this.city = '',
    this.description = '',
    this.logoUrl,
    this.website,
    this.instagram,
    this.verificationStatus = VerificationStatus.pending,
    this.viewCount = 0,
    this.saveCount = 0,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String brandName;
  final String category;
  final String city;
  final String description;
  final String? logoUrl;
  final String? website;
  final String? instagram;

  /// Changed only by an admin. This is an in-app check, not a government one.
  final VerificationStatus verificationStatus;
  final int viewCount;
  final int saveCount;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory BrandProfile.fromJson(Map<String, dynamic> json, String uid) =>
      BrandProfile(
        uid: uid,
        brandName: readString(json['brandName']),
        category: readString(json['category']),
        city: readString(json['city']),
        description: readString(json['description']),
        logoUrl: readOptionalString(json['logoUrl']),
        website: readOptionalString(json['website']),
        instagram: readOptionalString(json['instagram']),
        verificationStatus:
            VerificationStatus.fromValue(json['verificationStatus'] as String?),
        viewCount: readInt(json['viewCount']),
        saveCount: readInt(json['saveCount']),
        isDemo: readBool(json['isDemo']),
        createdAt: readDateOrNow(json['createdAt']),
        updatedAt: readDateOrNow(json['updatedAt']),
      );

  /// Fields the brand itself may edit. Verification status and counters are
  /// deliberately left out.
  Map<String, dynamic> toEditableJson() => {
        'uid': uid,
        'brandName': brandName,
        'category': category,
        'city': city,
        'description': description,
        'logoUrl': logoUrl,
        'website': website,
        'instagram': instagram,
      };

  Map<String, dynamic> toJson() => {
        ...toEditableJson(),
        'verificationStatus': verificationStatus.value,
        'viewCount': viewCount,
        'saveCount': saveCount,
        'isDemo': isDemo,
        'createdAt': writeDate(createdAt),
        'updatedAt': writeDate(updatedAt),
      };

  BrandProfile copyWith({
    String? brandName,
    String? category,
    String? city,
    String? description,
    String? logoUrl,
    String? website,
    String? instagram,
  }) =>
      BrandProfile(
        uid: uid,
        brandName: brandName ?? this.brandName,
        category: category ?? this.category,
        city: city ?? this.city,
        description: description ?? this.description,
        logoUrl: logoUrl ?? this.logoUrl,
        website: website ?? this.website,
        instagram: instagram ?? this.instagram,
        verificationStatus: verificationStatus,
        viewCount: viewCount,
        saveCount: saveCount,
        isDemo: isDemo,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Private verification details, stored at
/// `brandProfiles/{uid}/private/verification`.
/// Only the brand itself and admins can read this.
class BrandVerification {
  const BrandVerification({
    this.panNumber = '',
    this.panDocumentUrl,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String panNumber;
  final String? panDocumentUrl;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  bool get hasPan => panNumber.isNotEmpty;

  factory BrandVerification.fromJson(Map<String, dynamic> json) =>
      BrandVerification(
        panNumber: readString(json['panNumber']),
        panDocumentUrl: readOptionalString(json['panDocumentUrl']),
        submittedAt: readDate(json['submittedAt']),
        reviewedBy: readOptionalString(json['reviewedBy']),
        reviewedAt: readDate(json['reviewedAt']),
        rejectionReason: readOptionalString(json['rejectionReason']),
      );
}
