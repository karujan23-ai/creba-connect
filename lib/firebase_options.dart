// TEMPORARY placeholder used only with the local Firebase emulators.
//
// `flutterfire configure` replaces this whole file with the real settings
// of the Firebase project. Until then the app can only run in emulator mode.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:000000000000:web:0000000000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'demo-creba-connect',
      );
}
