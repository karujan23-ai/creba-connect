import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';

/// Opens a web link in the phone's browser. Returns false if it could not.
Future<bool> openLink(String url) async {
  final withScheme = url.startsWith('http') ? url : 'https://$url';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Opens [screen] on top of the current one.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

/// Closes every opened screen and signs the user out. `AuthGate` then shows
/// the sign-in screen.
Future<void> signOutAndReset(BuildContext context) {
  final auth = context.read<AuthProvider>();
  // A message from the signed-in session must not follow the user onto the
  // sign-in screen.
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..clearSnackBars();
  Navigator.of(context).popUntil((route) => route.isFirst);
  return auth.signOut();
}
