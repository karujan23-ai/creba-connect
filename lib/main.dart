import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

/// Where the app starts.
///
/// 1. Connect to Firebase.
/// 2. Open the small on-device store that remembers theme and currency.
/// 3. Show the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final preferences = await SharedPreferences.getInstance();
  runApp(CrebaConnectApp(preferences: preferences));
}
