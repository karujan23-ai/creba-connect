import '../utils/formatters.dart';
import 'model_utils.dart';

/// A creator's "I'm available" post, stored at
/// `creatorAvailabilityPosts/{id}`.
class AvailabilityPost {
  const AvailabilityPost({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.niches = const [],
    this.city = '',
    required this.availableFrom,
    required this.availableTo,
    this.workTypes = const [],
    this.rateFrom,
    this.currency = Currency.npr,
    this.note = '',
    this.isActive = true,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// UID of the creator that owns this post.
  final String creatorId;
  final String creatorName;
  final String title;
  final List<String> niches;
  final String city;
  final DateTime availableFrom;
  final DateTime availableTo;
  final List<String> workTypes;
  final num? rateFrom;
  final Currency currency;
  final String note;

  /// The creator can switch a post off without deleting it.
  final bool isActive;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasEnded => availableTo.isBefore(DateTime.now());

  factory AvailabilityPost.fromJson(Map<String, dynamic> json, String id) =>
      AvailabilityPost(
        id: id,
        creatorId: readString(json['creatorId']),
        creatorName: readString(json['creatorName']),
        title: readString(json['title']),
        niches: readStringList(json['niches']),
        city: readString(json['city']),
        availableFrom: readDateOrNow(json['availableFrom']),
        availableTo: readDateOrNow(json['availableTo']),
        workTypes: readStringList(json['workTypes']),
        rateFrom: json['rateFrom'] is num ? json['rateFrom'] as num : null,
        currency: Currency.fromCode(json['currency'] as String?),
        note: readString(json['note']),
        isActive: readBool(json['isActive'], true),
        isDemo: readBool(json['isDemo']),
        createdAt: readDateOrNow(json['createdAt']),
        updatedAt: readDateOrNow(json['updatedAt']),
      );

  Map<String, dynamic> toEditableJson() => {
        'title': title,
        'niches': niches,
        'city': city,
        'availableFrom': writeDate(availableFrom),
        'availableTo': writeDate(availableTo),
        'workTypes': workTypes,
        'rateFrom': rateFrom,
        'currency': currency.code,
        'note': note,
        'isActive': isActive,
      };

  Map<String, dynamic> toJson() => {
        ...toEditableJson(),
        'creatorId': creatorId,
        'creatorName': creatorName,
        'isDemo': isDemo,
        'createdAt': writeDate(createdAt),
        'updatedAt': writeDate(updatedAt),
      };
}
