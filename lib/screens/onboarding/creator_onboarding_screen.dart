import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../providers/category_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import 'onboarding_scaffold.dart';

/// Five short steps that turn a new creator account into a profile:
/// what you do → niches → city → bio → links (optional).
///
/// Finishing creates `creatorProfiles/{uid}` — the first CREATE the creator
/// performs in Firestore.
class CreatorOnboardingScreen extends StatefulWidget {
  const CreatorOnboardingScreen({super.key});

  @override
  State<CreatorOnboardingScreen> createState() => _CreatorOnboardingScreenState();
}

class _CreatorOnboardingScreenState extends State<CreatorOnboardingScreen> {
  static const _totalSteps = 5;

  final _linksFormKey = GlobalKey<FormState>();
  final _bio = TextEditingController();
  final _instagram = TextEditingController();
  final _tiktok = TextEditingController();
  final _youtube = TextEditingController();
  final _portfolio = TextEditingController();
  final _photo = TextEditingController();

  int _step = 0;
  Set<String> _types = {};
  Set<String> _niches = {};
  String? _city;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [_bio, _instagram, _tiktok, _youtube, _portfolio, _photo]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Returns a message when the current step is not filled in properly.
  String? _problemWithStep() => switch (_step) {
        0 when _types.isEmpty => 'Choose at least one option.',
        1 when _niches.isEmpty => 'Choose at least one niche.',
        2 when _city == null => 'Choose your city.',
        3 when _bio.text.trim().length < 20 =>
          'Write at least a sentence about yourself (20 characters).',
        _ => null,
      };

  void _next() {
    final problem = _problemWithStep();
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else if (_linksFormKey.currentState?.validate() ?? true) {
      _finish(includeLinks: true);
    }
  }

  Future<void> _finish({required bool includeLinks}) async {
    final user = context.read<UserProvider>().user!;
    String? optional(TextEditingController controller) {
      final text = controller.text.trim();
      return includeLinks && text.isNotEmpty ? text : null;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final error = await context.read<CreatorProvider>().createProfile(
          CreatorProfile(
            uid: user.uid,
            fullName: user.displayName,
            creatorTypes: _types.toList(),
            niches: _niches.toList(),
            city: _city!,
            bio: _bio.text.trim(),
            instagram: optional(_instagram),
            tiktok: optional(_tiktok),
            youtube: optional(_youtube),
            portfolioUrl: optional(_portfolio),
            photoUrl: optional(_photo),
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isSaving = false);
      showSnack(context, error);
      return;
    }
    // AuthGate moves on to the home screen as soon as this is saved.
    final onboardingError =
        await context.read<UserProvider>().completeOnboarding(city: _city!);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (onboardingError != null) showSnack(context, onboardingError);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final isLast = _step == _totalSteps - 1;

    final (String title, String subtitle, Widget content) = switch (_step) {
      0 => (
          'What do you do?',
          'Pick everything that describes your work.',
          MultiSelectChips(
            options: categories.creatorTypes,
            selected: _types,
            onChanged: (value) => setState(() => _types = value),
          ),
        ),
      1 => (
          'Your niches',
          'Brands search by niche. Choose the ones you create for.',
          MultiSelectChips(
            options: categories.niches,
            selected: _niches,
            onChanged: (value) => setState(() => _niches = value),
          ),
        ),
      2 => (
          'Where are you based?',
          'Many shoots are on-site, so brands filter by city.',
          SingleSelectChips(
            options: AppConstants.cities,
            selected: _city,
            allowClear: false,
            onChanged: (value) => setState(() => _city = value),
          ),
        ),
      3 => (
          'A short bio',
          'Two or three sentences a brand will read first.',
          AppTextField(
            label: 'Bio',
            controller: _bio,
            hint: 'Fashion model and UGC creator based in Kathmandu…',
            maxLines: 5,
            maxLength: 400,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      _ => (
          'Links',
          'Optional. You can add or change these later from your profile.',
          Form(
            key: _linksFormKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Instagram username',
                  optional: true,
                  controller: _instagram,
                  prefixText: '@',
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'TikTok username',
                  optional: true,
                  controller: _tiktok,
                  prefixText: '@',
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'YouTube channel',
                  optional: true,
                  controller: _youtube,
                  prefixText: '@',
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Portfolio link',
                  optional: true,
                  controller: _portfolio,
                  hint: 'https://',
                  keyboardType: TextInputType.url,
                  validator: Validators.url,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Profile photo link',
                  optional: true,
                  controller: _photo,
                  hint: 'https://',
                  helper: 'Paste a link to an image. Without one, your initials are shown.',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: Validators.url,
                ),
              ],
            ),
          ),
        ),
    };

    return OnboardingScaffold(
      step: _step,
      totalSteps: _totalSteps,
      title: title,
      subtitle: subtitle,
      isLoading: _isSaving,
      nextLabel: isLast ? 'Finish' : 'Continue',
      onBack: _step == 0 ? null : () => setState(() => _step--),
      onSkip: isLast ? () => _finish(includeLinks: false) : null,
      onNext: _next,
      child: content,
    );
  }
}
