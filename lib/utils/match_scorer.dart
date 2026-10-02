import '../models/brand_profile.dart';
import '../models/creator_profile.dart';
import '../models/hiring_post.dart';
import 'constants.dart';
import 'formatters.dart';

/// "Best Fit" — a simple, rule-based compatibility score from 0 to 100.
///
/// This is NOT artificial intelligence. It adds up points for things that
/// match, using fixed weights:
///
///   Creator type matches ....... 25
///   Niche matches .............. 30
///   Same city (or remote) ...... 15
///   Creator is available ....... 15
///   Rate fits the budget ....... 15
///                               ---
///                               100
///
/// The same rules are used in both directions: brands see how well a creator
/// fits, and creators see how well an opportunity fits them.
class MatchScorer {
  MatchScorer._();

  static const _typeWeight = 25;
  static const _nicheWeight = 30;
  static const _locationWeight = 15;
  static const _availabilityWeight = 15;
  static const _budgetWeight = 15;

  /// How well [creator] fits a specific hiring [post].
  static int creatorForPost(CreatorProfile creator, HiringPost post) {
    final score = _typePoints(creator.creatorTypes, post.creatorTypes) +
        _nichePoints(creator.niches, post.niches) +
        _locationPoints(creator.city, post.city, post.isRemote) +
        (creator.isAvailable ? _availabilityWeight : 0) +
        _budgetPoints(creator.startingRate, post);
    return score.round().clamp(0, 100);
  }

  /// How well [creator] fits a [brand] in general, when the brand has no
  /// specific post in mind. The brand's business category stands in for the
  /// niches it would want, and there is no budget to compare against, so the
  /// remaining weights are scaled up to 100.
  static int creatorForBrand(CreatorProfile creator, BrandProfile brand) {
    final wantedNiches = AppConstants.categoryToNiches[brand.category] ?? const [];
    final earned = _nichePoints(creator.niches, wantedNiches) +
        _locationPoints(creator.city, brand.city, false) +
        (creator.isAvailable ? _availabilityWeight : 0);
    const possible = _nicheWeight + _locationWeight + _availabilityWeight;
    return (earned / possible * 100).round().clamp(0, 100);
  }

  static double _typePoints(List<String> has, List<String> wanted) {
    if (wanted.isEmpty) return _typeWeight.toDouble();
    return has.any(wanted.contains) ? _typeWeight.toDouble() : 0;
  }

  /// Partial credit: matching 1 of 2 wanted niches earns half the points.
  static double _nichePoints(List<String> has, List<String> wanted) {
    if (wanted.isEmpty) return _nicheWeight.toDouble();
    final matches = wanted.where(has.contains).length;
    return _nicheWeight * matches / wanted.length;
  }

  static double _locationPoints(String creatorCity, String wantedCity, bool remote) {
    if (remote || wantedCity.isEmpty) return _locationWeight.toDouble();
    return creatorCity.toLowerCase() == wantedCity.toLowerCase()
        ? _locationWeight.toDouble()
        : 0;
  }

  static double _budgetPoints(num? creatorRateNpr, HiringPost post) {
    final ceiling = post.budgetCeiling;
    // Negotiable budget or no rate given: neither a match nor a mismatch.
    if (ceiling == null || creatorRateNpr == null) return _budgetWeight * 0.6;

    final ceilingNpr = Money.convert(ceiling, post.currency, Currency.npr);
    if (creatorRateNpr <= ceilingNpr) return _budgetWeight.toDouble();
    // Slightly over budget (up to 25%) still earns half.
    if (creatorRateNpr <= ceilingNpr * 1.25) return _budgetWeight * 0.5;
    return 0;
  }
}
