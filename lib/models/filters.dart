import 'creator_profile.dart';
import 'hiring_post.dart';

/// The search text and filter choices on the Discover Creators screen.
///
/// Firestore has no full-text search, so the app loads a limited list of
/// creators and narrows it down here, on the device.
class CreatorFilter {
  const CreatorFilter({
    this.query = '',
    this.types = const {},
    this.niches = const {},
    this.city,
    this.gender,
    this.language,
    this.workType,
    this.maxRate,
    this.availableOnly = false,
  });

  final String query;
  final Set<String> types;
  final Set<String> niches;
  final String? city;
  final String? gender;
  final String? language;
  final String? workType;

  /// Highest starting rate (NPR) the brand is willing to see.
  final num? maxRate;
  final bool availableOnly;

  /// How many filters are switched on (the search text is not counted).
  int get activeCount =>
      types.length +
      niches.length +
      [city, gender, language, workType, maxRate].where((v) => v != null).length +
      (availableOnly ? 1 : 0);

  bool matches(CreatorProfile creator) {
    if (availableOnly && !creator.isAvailable) return false;
    if (types.isNotEmpty && !creator.creatorTypes.any(types.contains)) return false;
    if (niches.isNotEmpty && !creator.niches.any(niches.contains)) return false;
    if (city != null && creator.city != city) return false;
    if (gender != null && creator.gender != gender) return false;
    if (language != null && !creator.languages.contains(language)) return false;
    if (workType != null && !creator.workTypes.contains(workType)) return false;
    if (maxRate != null &&
        creator.startingRate != null &&
        creator.startingRate! > maxRate!) {
      return false;
    }
    return _matchesQuery(creator);
  }

  bool _matchesQuery(CreatorProfile creator) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    final searchable = [
      creator.fullName,
      creator.city,
      ...creator.creatorTypes,
      ...creator.niches,
    ].join(' ').toLowerCase();
    return searchable.contains(text);
  }

  CreatorFilter withQuery(String query) => CreatorFilter(
        query: query,
        types: types,
        niches: niches,
        city: city,
        gender: gender,
        language: language,
        workType: workType,
        maxRate: maxRate,
        availableOnly: availableOnly,
      );
}

/// The search text and filter choices on the creator's opportunity feed.
class JobFilter {
  const JobFilter({
    this.query = '',
    this.niches = const {},
    this.creatorType,
    this.city,
    this.workType,
    this.remoteOnly = false,
  });

  final String query;
  final Set<String> niches;
  final String? creatorType;
  final String? city;
  final String? workType;
  final bool remoteOnly;

  int get activeCount =>
      niches.length +
      [creatorType, city, workType].where((v) => v != null).length +
      (remoteOnly ? 1 : 0);

  bool matches(HiringPost post) {
    if (remoteOnly && !post.isRemote) return false;
    if (niches.isNotEmpty && !post.niches.any(niches.contains)) return false;
    if (creatorType != null && !post.creatorTypes.contains(creatorType)) return false;
    if (city != null && post.city != city) return false;
    if (workType != null && post.workType != workType) return false;

    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    final searchable = [
      post.title,
      post.brandName,
      post.city,
      post.workType,
      ...post.niches,
      ...post.creatorTypes,
    ].join(' ').toLowerCase();
    return searchable.contains(text);
  }

  JobFilter withQuery(String query) => JobFilter(
        query: query,
        niches: niches,
        creatorType: creatorType,
        city: city,
        workType: workType,
        remoteOnly: remoteOnly,
      );
}
