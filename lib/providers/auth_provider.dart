import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/app_exception.dart';

enum AuthStatus {
  /// The app has just started and Firebase has not answered yet.
  unknown,
  signedOut,
  signedIn,
}

/// Holds the sign-in state for the whole app.
///
/// It listens to Firebase's auth stream, so the state survives app restarts
/// (Firebase remembers the session) and screens never ask Firebase directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._userService) {
    _subscription = _authService.uidChanges.listen(_onAuthChanged);
  }

  final AuthService _authService;
  final UserService _userService;
  late final StreamSubscription<String?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  String? _uid;
  bool _isBusy = false;
  bool _isRegistering = false;

  AuthStatus get status => _status;
  String? get uid => _uid;
  String? get email => _authService.currentEmail;

  /// True while a sign-in, sign-up or reset request is running.
  bool get isBusy => _isBusy;

  /// True between creating the login and saving the account record, so the
  /// app can show "setting up" instead of "account not found".
  bool get isRegistering => _isRegistering;

  void _onAuthChanged(String? uid) {
    _uid = uid;
    _status = uid == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<String?> signIn({required String email, required String password}) =>
      _run(() => _authService.signIn(email: email, password: password));

  /// Creates the login, then the `users/{uid}` record that stores the role.
  /// The role can only be creator or brand here; admin is never offered.
  Future<String?> register({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    required String phone,
  }) {
    assert(role != UserRole.admin, 'Admins are assigned manually in Firestore.');
    _isRegistering = true;
    return _run(() async {
      final uid = await _authService.signUp(email: email, password: password);
      await _userService.createUser(
        AppUser(
          uid: uid,
          email: email.trim(),
          role: role,
          displayName: name.trim(),
          phone: phone.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }).whenComplete(() {
      _isRegistering = false;
      notifyListeners();
    });
  }

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _authService.sendPasswordReset(email));

  Future<void> signOut() => _authService.signOut();

  Future<String?> _run(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    final error = await guard(action);
    _isBusy = false;
    notifyListeners();
    return error;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
