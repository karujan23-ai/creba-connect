import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../admin/admin_shell.dart';
import '../brand/brand_shell.dart';
import '../creator/creator_shell.dart';
import '../onboarding/brand_onboarding_screen.dart';
import '../onboarding/creator_onboarding_screen.dart';
import 'auth_flow.dart';

/// Decides which part of the app the user is allowed to see.
///
/// This is the only way into the app, so a signed-out user can never reach a
/// protected screen: there is simply no route to one. The Firestore security
/// rules enforce the same thing on the server.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    final (String key, Widget screen) = switch (auth.status) {
      AuthStatus.unknown => ('splash', const SplashScreen()),
      AuthStatus.signedOut => ('auth', const AuthFlow()),
      AuthStatus.signedIn => _signedIn(auth, userProvider),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: KeyedSubtree(key: ValueKey(key), child: screen),
    );
  }

  (String, Widget) _signedIn(AuthProvider auth, UserProvider userProvider) {
    if (userProvider.error != null) {
      return ('problem', _AccountProblem(message: userProvider.error!));
    }
    final user = userProvider.user;
    if (user == null) {
      // The account record is written a moment after the login is created.
      if (userProvider.isLoading || auth.isRegistering) {
        return ('splash', const SplashScreen(message: 'Setting things up…'));
      }
      return (
        'problem',
        const _AccountProblem(
          message: 'We could not find your account details. '
              'Please sign out and register again.',
        ),
      );
    }
    if (!user.isActive) {
      return (
        'problem',
        const _AccountProblem(
          message: 'This account has been suspended. '
              'Please contact support if you think this is a mistake.',
        ),
      );
    }
    return _home(user);
  }

  (String, Widget) _home(AppUser user) {
    if (user.isAdmin) return ('admin', const AdminShell());
    if (!user.onboardingComplete) {
      return user.isCreator
          ? ('creator-onboarding', const CreatorOnboardingScreen())
          : ('brand-onboarding', const BrandOnboardingScreen());
    }
    return user.isCreator
        ? ('creator', const CreatorShell())
        : ('brand', const BrandShell());
  }
}

/// Shown for a moment while Firebase checks for a saved session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wordmark(size: 40),
              const SizedBox(height: 28),
              LoadingState(message: message),
            ],
          ),
        ),
      );
}

/// The app name set in the serif display face.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) => Text(
        AppConstants.appName,
        style: context.textTheme.displaySmall?.copyWith(fontSize: size),
      );
}

class _AccountProblem extends StatelessWidget {
  const _AccountProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Wordmark(),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge
                        ?.copyWith(color: context.palette.textMuted),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Sign out',
                    expand: false,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.read<AuthProvider>().signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
