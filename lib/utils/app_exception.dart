import 'package:firebase_core/firebase_core.dart';

/// An error with a message that is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns any error into a short, friendly sentence.
/// Raw Firebase errors are never shown to users.
String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is FirebaseException) return _messageForCode(error.code);
  return _generic;
}

const _generic = 'Something went wrong. Please try again.';

String _messageForCode(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Incorrect email or password.';
    case 'invalid-email':
      return 'That email address does not look right.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Please choose a stronger password (at least 6 characters).';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
    case 'unavailable':
      return 'No internet connection. Please check and try again.';
    case 'permission-denied':
      return 'You do not have permission to do that.';
    case 'not-found':
      return 'That item no longer exists.';
    default:
      return _generic;
  }
}

/// Runs [action] and returns `null` on success or a friendly message on
/// failure. Providers use this so screens only have to show the message.
Future<String?> guard(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } catch (error) {
    return friendlyError(error);
  }
}
