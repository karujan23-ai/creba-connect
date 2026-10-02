import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onShowRegister});

  final VoidCallback onShowRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context
        .read<AuthProvider>()
        .signIn(email: _email.text, password: _password.text);
    // On success AuthGate swaps this screen out, so there is nothing to do.
    if (mounted && error != null) showSnack(context, error);
  }

  Future<void> _resetPassword() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      showSnack(context, 'Enter your email above first, then tap "Forgot password?"');
      return;
    }
    final error = await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (!mounted) return;
    showResult(
      context,
      error,
      success: 'If that email has an account, a reset link is on its way.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((auth) => auth.isBusy);
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ContentWidth(
              maxWidth: 420,
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Wordmark(size: 44),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.tagline,
                        style: context.textTheme.bodyLarge
                            ?.copyWith(color: palette.textMuted),
                      ),
                      const SizedBox(height: 44),
                      AppTextField(
                        label: 'Email',
                        controller: _email,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) =>
                            Validators.required(value, 'Password'),
                        onSubmitted: (_) => _signIn(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isBusy ? null : _resetPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: palette.textMuted,
                            textStyle: context.textTheme.labelMedium,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(label: 'Sign in', isLoading: isBusy, onPressed: _signIn),
                      const SizedBox(height: 14),
                      AppButton(
                        label: 'Create an account',
                        variant: AppButtonVariant.secondary,
                        onPressed: isBusy ? null : widget.onShowRegister,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
