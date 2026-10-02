import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../utils/app_exception.dart';

/// Base class for providers whose data belongs to the signed-in user.
///
/// When the user changes (sign in, sign out, or a different account) the
/// provider stops listening to the old user's data and starts listening to
/// the new user's. This is what stops one account from ever seeing another
/// account's leftover data on the same phone.
abstract class SessionProvider extends ChangeNotifier {
  AppUser? _session;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;

  /// The signed-in user's account record, or null when signed out.
  AppUser? get session => _session;

  String? get uid => _session?.uid;

  /// Called by `ChangeNotifierProxyProvider` whenever the account changes.
  void bind(AppUser? user) {
    final sameSession = user?.uid == _session?.uid && user?.role == _session?.role;
    _session = user;
    if (sameSession) return;

    _cancelSubscriptions();
    onSessionEnded();
    if (user != null) onSessionStarted(user);
    // bind() runs while widgets are building, so listeners are told afterwards.
    scheduleMicrotask(notifySafely);
  }

  /// Start listening to the new user's data here.
  @protected
  void onSessionStarted(AppUser user);

  /// Clear any data held for the previous user here.
  @protected
  void onSessionEnded();

  /// Listens to a Firestore stream and stops automatically on sign-out.
  @protected
  void listen<T>(
    Stream<T> stream,
    void Function(T data) onData, {
    void Function(String message)? onError,
  }) {
    _subscriptions.add(
      stream.listen(
        (data) {
          onData(data);
          notifySafely();
        },
        onError: (Object error) {
          onError?.call(friendlyError(error));
          notifySafely();
        },
      ),
    );
  }

  @protected
  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    super.dispose();
  }
}
