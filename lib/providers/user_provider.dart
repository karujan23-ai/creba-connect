import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../utils/app_exception.dart';

/// Holds the signed-in user's account record (`users/{uid}`): their role,
/// whether onboarding is finished, and whether the account is active.
class UserProvider extends ChangeNotifier {
  UserProvider(this._userService);

  final UserService _userService;
  StreamSubscription<AppUser?>? _subscription;

  String? _uid;
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True when someone is signed in but has no account record. This is
  /// normal for a moment during registration.
  bool get isMissing => _uid != null && !_isLoading && _user == null;

  /// Called whenever the signed-in UID changes.
  void bind(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _user = null;
    _error = null;
    _isLoading = uid != null;

    if (uid != null) {
      _subscription = _userService.watchUser(uid).listen(
        (user) {
          final firstLoad = _isLoading;
          _user = user;
          _isLoading = false;
          _error = null;
          notifyListeners();
          if (firstLoad && user != null) _userService.touchLastActive(uid).ignore();
        },
        onError: (Object error) {
          _isLoading = false;
          _error = friendlyError(error);
          notifyListeners();
        },
      );
    }
    scheduleMicrotask(notifyListeners);
  }

  Future<String?> completeOnboarding({required String city, String? displayName}) =>
      guard(() => _userService.updateUser(_uid!, {
            'onboardingComplete': true,
            'city': city,
            'displayName': ?displayName,
          }));

  /// Updates only the values that are given.
  Future<String?> updateBasics({String? displayName, String? phone, String? city}) =>
      guard(() => _userService.updateUser(_uid!, {
            'displayName': ?displayName,
            'phone': ?phone,
            'city': ?city,
          }));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
