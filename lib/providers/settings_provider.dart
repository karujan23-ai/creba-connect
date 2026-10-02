import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/formatters.dart';

/// Holds the display currency (NPR or USD) and saves it on the device.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._preferences) {
    _currency = Currency.fromCode(_preferences.getString(_key));
  }

  static const _key = 'display_currency';

  final SharedPreferences _preferences;
  late Currency _currency;

  Currency get currency => _currency;

  Future<void> setCurrency(Currency currency) async {
    if (currency == _currency) return;
    _currency = currency;
    notifyListeners();
    await _preferences.setString(_key, currency.code);
  }

  /// Formats [amount] in the user's chosen currency. See [Money.display].
  String money(num amount, [Currency stored = Currency.npr]) =>
      Money.display(amount, stored, _currency);
}
