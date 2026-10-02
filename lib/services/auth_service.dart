import 'package:firebase_auth/firebase_auth.dart';

/// Everything that talks to Firebase Authentication.
///
/// Firebase stores and checks the password. The app never sees or saves it
/// anywhere else.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the signed-in user's UID, or null when signed out. Firebase
  /// remembers the session on the device, so this also fires with the saved
  /// user when the app is reopened.
  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  String? get currentUid => _auth.currentUser?.uid;

  String? get currentEmail => _auth.currentUser?.email;

  /// Creates the account and returns the new UID.
  Future<String> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!.uid;
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
