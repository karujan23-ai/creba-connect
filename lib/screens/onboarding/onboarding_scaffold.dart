import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_palette.dart';
import '../../widgets/app_button.dart';
import '../../widgets/layout.dart';

/// The frame shared by every onboarding step: progress bar, heading, the
/// step's own content, and Back / Continue buttons.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.onSkip,
    this.nextLabel = 'Continue',
    this.isLoading = false,
  });

  /// Zero-based index of the current step.
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// Shown only on steps that may be left empty.
  final VoidCallback? onSkip;
  final String nextLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        body: SafeArea(
          child: ContentWidth(
            maxWidth: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        'Step ${step + 1} of $totalSteps',
                        style: context.textTheme.labelMedium
                            ?.copyWith(color: palette.textMuted),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.read<AuthProvider>().signOut(),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.textMuted,
                          textStyle: context.textTheme.labelMedium,
                        ),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (step + 1) / totalSteps),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        semanticsLabel: 'Onboarding progress',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textTheme.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: context.textTheme.bodyLarge
                              ?.copyWith(color: palette.textMuted),
                        ),
                        const SizedBox(height: 28),
                        child,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      if (onBack != null) ...[
                        AppButton(
                          label: 'Back',
                          variant: AppButtonVariant.secondary,
                          expand: false,
                          onPressed: isLoading ? null : onBack,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (onSkip != null) ...[
                        AppButton(
                          label: 'Skip',
                          variant: AppButtonVariant.ghost,
                          expand: false,
                          onPressed: isLoading ? null : onSkip,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: AppButton(
                          label: nextLabel,
                          isLoading: isLoading,
                          onPressed: onNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
