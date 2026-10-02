import '../models/creator_profile.dart';

/// Ranks creators for the home-screen sections using simple, measurable rules.
///
///   score = profile views × 1
///         + saves × 3                (a save shows more interest than a view)
///         + profile completeness ÷ 5 (0–20 points)
///         + 15 if the profile was updated in the last 7 days
///         + 10 if the creator is marked available
///         + 25 if the profile has an active boost
class TrendingScorer {
  TrendingScorer._();

  static double score(CreatorProfile creator) {
    final daysSinceUpdate = DateTime.now().difference(creator.updatedAt).inDays;
    return creator.viewCount * 1.0 +
        creator.saveCount * 3.0 +
        creator.completeness / 5 +
        (daysSinceUpdate <= 7 ? 15 : 0) +
        (creator.isAvailable ? 10 : 0) +
        (creator.isBoosted ? 25 : 0);
  }

  /// Highest score first.
  static List<CreatorProfile> trending(List<CreatorProfile> creators, {int take = 10}) {
    final sorted = [...creators]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.take(take).toList();
  }

  /// Profiles created in the last 30 days, best score first.
  static List<CreatorProfile> rising(List<CreatorProfile> creators, {int take = 10}) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return trending(
      creators.where((creator) => creator.createdAt.isAfter(cutoff)).toList(),
      take: take,
    );
  }

  /// Best-scoring creators who list [niche].
  static List<CreatorProfile> popularIn(
    List<CreatorProfile> creators,
    String niche, {
    int take = 10,
  }) =>
      trending(
        creators.where((creator) => creator.niches.contains(niche)).toList(),
        take: take,
      );

  /// Most recently updated first.
  static List<CreatorProfile> recentlyActive(
    List<CreatorProfile> creators, {
    int take = 10,
  }) {
    final sorted = [...creators]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(take).toList();
  }
}
