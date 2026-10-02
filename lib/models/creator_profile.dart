import 'model_utils.dart';

/// A creator's public profile, stored at `creatorProfiles/{uid}`.
class CreatorProfile {
  const CreatorProfile({
    required this.uid,
    required this.fullName,
    this.creatorTypes = const [],
    this.niches = const [],
    this.city = '',
    this.bio = '',
    this.photoUrl,
    this.gender,
    this.ageRange,
    this.languages = const [],
    this.skills = const [],
    this.instagram,
    this.tiktok,
    this.youtube,
    this.portfolioUrl,
    this.startingRate,
    this.workTypes = const [],
    this.isAvailable = true,
    this.previousCollaborations = const [],
    this.viewCount = 0,
    this.saveCount = 0,
    this.boostedUntil,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final List<String> creatorTypes;
  final List<String> niches;
  final String city;
  final String bio;
  final String? photoUrl;
  final String? gender;
  final String? ageRange;
  final List<String> languages;
  final List<String> skills;
  final String? instagram;
  final String? tiktok;
  final String? youtube;
  final String? portfolioUrl;

  /// Lowest rate in NPR. Null means "not set".
  final num? startingRate;
  final List<String> workTypes;
  final bool isAvailable;
  final List<String> previousCollaborations;
  final int viewCount;
  final int saveCount;

  /// Set by an admin when a profile boost is approved.
  final DateTime? boostedUntil;

  /// True for sample profiles created by the demo-data tool.
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isBoosted =>
      boostedUntil != null && boostedUntil!.isAfter(DateTime.now());

  String get typeLine => creatorTypes.join(' · ');

  /// How complete the profile is, from 0 to 100. Each filled-in part adds
  /// points; the weights add up to 100.
  int get completeness {
    var points = 0;
    if (fullName.isNotEmpty) points += 10;
    if (creatorTypes.isNotEmpty) points += 10;
    if (niches.isNotEmpty) points += 10;
    if (city.isNotEmpty) points += 10;
    if (bio.length >= 20) points += 15;
    if (startingRate != null) points += 10;
    if (workTypes.isNotEmpty) points += 10;
    if (languages.isNotEmpty) points += 5;
    if (skills.isNotEmpty) points += 5;
    if (photoUrl != null) points += 5;
    if (instagram != null || tiktok != null || youtube != null) points += 5;
    if (portfolioUrl != null) points += 5;
    return points;
  }

  factory CreatorProfile.fromJson(Map<String, dynamic> json, String uid) =>
      CreatorProfile(
        uid: uid,
        fullName: readString(json['fullName']),
        creatorTypes: readStringList(json['creatorTypes']),
        niches: readStringList(json['niches']),
        city: readString(json['city']),
        bio: readString(json['bio']),
        photoUrl: readOptionalString(json['photoUrl']),
        gender: readOptionalString(json['gender']),
        ageRange: readOptionalString(json['ageRange']),
        languages: readStringList(json['languages']),
        skills: readStringList(json['skills']),
        instagram: readOptionalString(json['instagram']),
        tiktok: readOptionalString(json['tiktok']),
        youtube: readOptionalString(json['youtube']),
        portfolioUrl: readOptionalString(json['portfolioUrl']),
        startingRate: json['startingRate'] is num ? json['startingRate'] as num : null,
        workTypes: readStringList(json['workTypes']),
        isAvailable: readBool(json['isAvailable'], true),
        previousCollaborations: readStringList(json['previousCollaborations']),
        viewCount: readInt(json['viewCount']),
        saveCount: readInt(json['saveCount']),
        boostedUntil: readDate(json['boostedUntil']),
        isDemo: readBool(json['isDemo']),
        createdAt: readDateOrNow(json['createdAt']),
        updatedAt: readDateOrNow(json['updatedAt']),
      );

  /// Everything the owner is allowed to edit. Counters and admin-only fields
  /// are written separately so they can never be overwritten by a profile edit.
  Map<String, dynamic> toEditableJson() => {
        'uid': uid,
        'fullName': fullName,
        'creatorTypes': creatorTypes,
        'niches': niches,
        'city': city,
        'bio': bio,
        'photoUrl': photoUrl,
        'gender': gender,
        'ageRange': ageRange,
        'languages': languages,
        'skills': skills,
        'instagram': instagram,
        'tiktok': tiktok,
        'youtube': youtube,
        'portfolioUrl': portfolioUrl,
        'startingRate': startingRate,
        'workTypes': workTypes,
        'isAvailable': isAvailable,
        'previousCollaborations': previousCollaborations,
      };

  Map<String, dynamic> toJson() => {
        ...toEditableJson(),
        'viewCount': viewCount,
        'saveCount': saveCount,
        'boostedUntil': writeDate(boostedUntil),
        'isDemo': isDemo,
        'createdAt': writeDate(createdAt),
        'updatedAt': writeDate(updatedAt),
      };

  CreatorProfile copyWith({
    String? fullName,
    List<String>? creatorTypes,
    List<String>? niches,
    String? city,
    String? bio,
    String? photoUrl,
    String? gender,
    String? ageRange,
    List<String>? languages,
    List<String>? skills,
    String? instagram,
    String? tiktok,
    String? youtube,
    String? portfolioUrl,
    num? startingRate,
    List<String>? workTypes,
    bool? isAvailable,
    List<String>? previousCollaborations,
  }) =>
      CreatorProfile(
        uid: uid,
        fullName: fullName ?? this.fullName,
        creatorTypes: creatorTypes ?? this.creatorTypes,
        niches: niches ?? this.niches,
        city: city ?? this.city,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        gender: gender ?? this.gender,
        ageRange: ageRange ?? this.ageRange,
        languages: languages ?? this.languages,
        skills: skills ?? this.skills,
        instagram: instagram ?? this.instagram,
        tiktok: tiktok ?? this.tiktok,
        youtube: youtube ?? this.youtube,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
        startingRate: startingRate ?? this.startingRate,
        workTypes: workTypes ?? this.workTypes,
        isAvailable: isAvailable ?? this.isAvailable,
        previousCollaborations:
            previousCollaborations ?? this.previousCollaborations,
        viewCount: viewCount,
        saveCount: saveCount,
        boostedUntil: boostedUntil,
        isDemo: isDemo,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
