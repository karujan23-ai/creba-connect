import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the chosen theme (Light / Dark / System) and saves it on the device
/// so the choice is still there after the app is closed.
///
/// Changing the theme only swaps colours. No screen is recreated, so nothing
/// the user was doing is lost.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences) {
    _mode = _fromName(_preferences.getString(_key));
  }

  static const _key = 'theme_mode';

  final SharedPreferences _preferences;
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _preferences.setString(_key, mode.name);
  }

  static ThemeMode _fromName(String? name) => ThemeMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ThemeMode.system,
      );
}
