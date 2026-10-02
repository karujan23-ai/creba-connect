import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

/// Switches between Sign In and Sign Up.
///
/// Both live inside the same route, so when sign-in succeeds there is no
/// leftover screen sitting on top of the app.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _showRegister = false;

  void _toggle() => setState(() => _showRegister = !_showRegister);

  @override
  Widget build(BuildContext context) => PopScope(
        // The system back button returns from Sign Up to Sign In.
        canPop: !_showRegister,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _toggle();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showRegister
              ? RegisterScreen(key: const ValueKey('register'), onShowLogin: _toggle)
              : LoginScreen(key: const ValueKey('login'), onShowRegister: _toggle),
        ),
      );
}
