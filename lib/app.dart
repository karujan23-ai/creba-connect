import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/admin_provider.dart';
import 'providers/application_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/category_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/creator_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/hiring_post_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/admin_service.dart';
import 'services/application_service.dart';
import 'services/auth_service.dart';
import 'services/availability_service.dart';
import 'services/brand_service.dart';
import 'services/category_service.dart';
import 'services/chat_service.dart';
import 'services/creator_service.dart';
import 'services/favorites_service.dart';
import 'services/hiring_post_service.dart';
import 'services/notification_service.dart';
import 'services/promotion_service.dart';
import 'services/report_service.dart';
import 'services/seed_service.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// The root of the app: registers every provider, applies the theme and
/// hands control to [AuthGate].
class CrebaConnectApp extends StatelessWidget {
  const CrebaConnectApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(preferences)),

        // Sign-in state. Everything below reacts to it.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(), userService),
        ),

        // The account record (role, onboarding) of whoever is signed in.
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(userService),
          update: (_, auth, userProvider) => userProvider!..bind(auth.uid),
        ),

        // Data providers. Each one starts listening when a user signs in
        // and clears itself when they sign out.
        _session((_) => CategoryProvider(CategoryService())),
        _session((_) => CreatorProvider(CreatorService())),
        _session((_) => BrandProvider(BrandService())),
        _session((_) => HiringPostProvider(HiringPostService())),
        _session((_) => AvailabilityProvider(AvailabilityService())),
        _session(
          (_) => ApplicationProvider(ApplicationService(), NotificationService()),
        ),
        _session((_) => ChatProvider(ChatService())),
        _session((_) => NotificationProvider(NotificationService())),
        _session((_) => FavoritesProvider(FavoritesService())),
        _session((_) => PromotionProvider(PromotionService())),
        _session(
          (_) => AdminProvider(
            adminService: AdminService(),
            brandService: BrandService(),
            hiringPostService: HiringPostService(),
            availabilityService: AvailabilityService(),
            reportService: ReportService(),
            seedService: SeedService(),
          ),
        ),
      ],
      child: const _ThemedApp(),
    );
  }

  /// Registers a provider that follows the signed-in user.
  static SingleChildWidget _session<T extends SessionProvider>(
    T Function(BuildContext context) create,
  ) =>
      ChangeNotifierProxyProvider<UserProvider, T>(
        create: create,
        update: (_, userProvider, provider) => provider!..bind(userProvider.user),
      );
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    // Only the theme mode is watched here, so switching theme repaints the
    // app with new colours without rebuilding or resetting any screen state.
    final themeMode = context.select<ThemeProvider, ThemeMode>((theme) => theme.mode);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
