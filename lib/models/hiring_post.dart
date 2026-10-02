import '../utils/formatters.dart';
import 'enums.dart';
import 'model_utils.dart';

/// A brand's "Hire a Creator" opportunity, stored at `hiringPosts/{id}`.
class HiringPost {
  const HiringPost({
    required this.id,
    required this.brandId,
    required this.brandName,
    this.brandVerified = false,
    required this.title,
    required this.description,
    this.creatorTypes = const [],
    this.niches = const [],
    this.city = '',
    this.isRemote = false,
    this.workType = '',
    this.startDate,
    this.duration = '',
    this.budgetType = BudgetType.negotiable,
    this.budgetMin,
    this.budgetMax,
    this.currency = Currency.npr,
    this.creatorsNeeded = 1,
    this.requirements = const [],
    this.deliverables = const [],
    this.deadline,
    this.contactPreference = 'In-app chat',
    this.imageUrl,
    this.status = PostStatus.open,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.promotedUntil,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// UID of the brand that owns this post.
  final String brandId;
  final String brandName;
  final bool brandVerified;
  final String title;
  final String description;
  final List<String> creatorTypes;
  final List<String> niches;
  final String city;
  final bool isRemote;
  final String workType;
  final DateTime? startDate;
  final String duration;
  final BudgetType budgetType;
  final num? budgetMin;
  final num? budgetMax;
  final Currency currency;
  final int creatorsNeeded;
  final List<String> requirements;
  final List<String> deliverables;
  final DateTime? deadline;
  final String contactPreference;
  final String? imageUrl;
  final PostStatus status;
  final int viewCount;
  final int applicationCount;

  /// Set by an admin when a promotion is approved.
  final DateTime? promotedUntil;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == PostStatus.open;

  bool get isPromoted =>
      promotedUntil != null && promotedUntil!.isAfter(DateTime.now());

  bool get deadlinePassed =>
      deadline != null && deadline!.isBefore(DateTime.now());

  String get locationLabel => isRemote
      ? (city.isEmpty ? 'Remote' : '$city · Remote')
      : city;

  /// The highest amount the brand will pay, in the post's own currency.
  /// Null when the budget is negotiable.
  num? get budgetCeiling => budgetType == BudgetType.range
      ? (budgetMax ?? budgetMin)
      : (budgetType == BudgetType.fixed ? budgetMin : null);

  factory HiringPost.fromJson(Map<String, dynamic> json, String id) =>
      HiringPost(
        id: id,
        brandId: readString(json['brandId']),
        brandName: readString(json['brandName']),
        brandVerified: readBool(json['brandVerified']),
        title: readString(json['title']),
        description: readString(json['description']),
        creatorTypes: readStringList(json['creatorTypes']),
        niches: readStringList(json['niches']),
        city: readString(json['city']),
        isRemote: readBool(json['isRemote']),
        workType: readString(json['workType']),
        startDate: readDate(json['startDate']),
        duration: readString(json['duration']),
        budgetType: BudgetType.fromValue(json['budgetType'] as String?),
        budgetMin: json['budgetMin'] is num ? json['budgetMin'] as num : null,
        budgetMax: json['budgetMax'] is num ? json['budgetMax'] as num : null,
        currency: Currency.fromCode(json['currency'] as String?),
        creatorsNeeded: readInt(json['creatorsNeeded'], 1),
        requirements: readStringList(json['requirements']),
        deliverables: readStringList(json['deliverables']),
        deadline: readDate(json['deadline']),
        contactPreference: readString(json['contactPreference'], 'In-app chat'),
        imageUrl: readOptionalString(json['imageUrl']),
        status: PostStatus.fromValue(json['status'] as String?),
        viewCount: readInt(json['viewCount']),
        applicationCount: readInt(json['applicationCount']),
        promotedUntil: readDate(json['promotedUntil']),
        isDemo: readBool(json['isDemo']),
        createdAt: readDateOrNow(json['createdAt']),
        updatedAt: readDateOrNow(json['updatedAt']),
      );

  /// Fields the owning brand may edit.
  Map<String, dynamic> toEditableJson() => {
        'title': title,
        'description': description,
        'creatorTypes': creatorTypes,
        'niches': niches,
        'city': city,
        'isRemote': isRemote,
        'workType': workType,
        'startDate': writeDate(startDate),
        'duration': duration,
        'budgetType': budgetType.value,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'currency': currency.code,
        'creatorsNeeded': creatorsNeeded,
        'requirements': requirements,
        'deliverables': deliverables,
        'deadline': writeDate(deadline),
        'contactPreference': contactPreference,
        'imageUrl': imageUrl,
        'status': status.value,
      };

  Map<String, dynamic> toJson() => {
        ...toEditableJson(),
        'brandId': brandId,
        'brandName': brandName,
        'brandVerified': brandVerified,
        'viewCount': viewCount,
        'applicationCount': applicationCount,
        'promotedUntil': writeDate(promotedUntil),
        'isDemo': isDemo,
        'createdAt': writeDate(createdAt),
        'updatedAt': writeDate(updatedAt),
      };
}
