import 'package:intl/intl.dart';

import 'app_config.dart';

/// The two currencies the app can show.
enum Currency {
  npr('NPR'),
  usd('USD');

  const Currency(this.code);

  final String code;

  static Currency fromCode(String? code) =>
      code == 'USD' ? Currency.usd : Currency.npr;
}

/// Money formatting and the fixed NPR ↔ USD conversion.
class Money {
  Money._();

  static final _whole = NumberFormat('#,##0');

  /// "NPR 15,000"
  static String format(num amount, Currency currency) =>
      '${currency.code} ${_whole.format(amount.round())}';

  static num convert(num amount, Currency from, Currency to) {
    if (from == to) return amount;
    return from == Currency.npr
        ? amount / AppConfig.nprPerUsd
        : amount * AppConfig.nprPerUsd;
  }

  /// Shows [amount] in the currency the user picked in Settings. When that is
  /// different from the currency it was entered in, the result is marked "≈"
  /// because the rate is fixed and only approximate.
  static String display(num amount, Currency stored, Currency preferred) {
    if (stored == preferred) return format(amount, stored);
    return '≈ ${format(convert(amount, stored, preferred), preferred)}';
  }

  static num? parse(String text) => num.tryParse(text.trim().replaceAll(',', ''));
}

/// Date helpers.
class Dates {
  Dates._();

  static final _short = DateFormat('MMM d');
  static final _full = DateFormat('MMM d, yyyy');
  static final _time = DateFormat('h:mm a');

  static String short(DateTime date) => _short.format(date);

  static String full(DateTime date) => _full.format(date);

  static String time(DateTime date) => _time.format(date);

  /// "Oct 10–20" or "Oct 28 – Nov 3"
  static String range(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month) {
      return '${_short.format(from)}–${to.day}';
    }
    return '${_short.format(from)} – ${_short.format(to)}';
  }

  /// "Just now", "5m ago", "3h ago", "2d ago", then a date.
  static String ago(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return _short.format(date);
  }

  /// Label used between chat messages: "Today", "Yesterday" or a date.
  static String dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo == 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    return _full.format(date);
  }
}

/// "Good morning" / "Good afternoon" / "Good evening"
String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// First letters of up to two words: "Anisha Sharma" → "AS".
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}
