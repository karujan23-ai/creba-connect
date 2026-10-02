import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';

/// Sign up. The user picks Creator or Brand here; there is no way to pick
/// Admin, which is only ever assigned by hand in Firestore.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onShowLogin});

  final VoidCallback onShowLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.creator;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().register(
          role: _role,
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
        );
    if (mounted && error != null) showSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((auth) => auth.isBusy);
    final isCreator = _role == UserRole.creator;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ContentWidth(
              maxWidth: 420,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create your account', style: context.textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us who you are. You can finish your profile next.',
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: context.palette.textMuted),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleOption(
                            title: 'Creator',
                            subtitle: 'Find brand work',
                            selected: isCreator,
                            onTap: () => setState(() => _role = UserRole.creator),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleOption(
                            title: 'Brand',
                            subtitle: 'Hire creators',
                            selected: !isCreator,
                            onTap: () => setState(() => _role = UserRole.brand),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: isCreator ? 'Full name' : 'Business name',
                      controller: _name,
                      hint: isCreator ? 'Anisha Sharma' : 'Your brand',
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => Validators.minLength(
                        value,
                        2,
                        isCreator ? 'Full name' : 'Business name',
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phone,
                      hint: '98XXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      isPassword: true,
                      helper: 'At least 6 characters',
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Create account',
                      isLoading: isBusy,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: isBusy ? null : widget.onShowLogin,
                        child: const Text('I already have an account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? palette.text : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: context.textTheme.titleMedium),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: selected ? palette.text : palette.border,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: context.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
