/// Values that tune how the app behaves. Change them here, in one place.
class AppConfig {
  AppConfig._();

  /// Fixed conversion rate used to show approximate prices in the other
  /// currency. This is NOT a live exchange rate, so converted prices are always
  /// labelled with "≈".
  static const double nprPerUsd = 134;

  /// How many documents a feed loads at most. Keeps Firestore reads low.
  static const int feedLimit = 60;
  static const int creatorListLimit = 100;
  static const int adminListLimit = 200;

  /// Layouts never grow wider than this, so tablets get a centred column.
  static const double maxContentWidth = 640;
}
