import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Connects the app to Firebase when it starts.
///
/// Normally this is the real Firebase project. For development it can use
/// the Firebase Local Emulator Suite instead (a pretend Firebase running on
/// this computer, so tests never touch real data). That mode is switched on
/// only when the app is started with:
///
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const _emulatorHost = String.fromEnvironment('EMULATOR_HOST');

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!_useEmulator) return;

    // An Android emulator reaches the computer it runs on at 10.0.2.2.
    final host = _emulatorHost.isNotEmpty
        ? _emulatorHost
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    debugPrint('Using the Firebase emulators at $host');
  }
}
