import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/brand_profile.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import 'onboarding_scaffold.dart';

/// Six short steps that set up a brand:
/// name → category → city → description → PAN → logo and links.
///
/// Finishing creates `brandProfiles/{uid}` with verification "pending".
class BrandOnboardingScreen extends StatefulWidget {
  const BrandOnboardingScreen({super.key});

  @override
  State<BrandOnboardingScreen> createState() => _BrandOnboardingScreenState();
}

class _BrandOnboardingScreenState extends State<BrandOnboardingScreen> {
  static const _totalSteps = 6;

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: context.read<UserProvider>().user?.displayName ?? '',
  );
  final _description = TextEditingController();
  final _pan = TextEditingController();
  final _logo = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();

  int _step = 0;
  String? _category;
  String? _city;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [_name, _description, _pan, _logo, _website, _instagram]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _problemWithStep() => switch (_step) {
        0 when _name.text.trim().length < 2 => 'Enter your business name.',
        1 when _category == null => 'Choose a category.',
        2 when _city == null => 'Choose your city.',
        3 when _description.text.trim().length < 20 =>
          'Describe your business in at least a sentence (20 characters).',
        _ => null,
      };

  void _next() {
    final problem = _problemWithStep();
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    // Steps 5 and 6 contain validated fields (PAN format, links).
    if (!(_formKey.currentState?.validate() ?? true)) return;

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _skip() {
    if (_step == 4) _pan.clear();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _logo.clear();
      _website.clear();
      _instagram.clear();
      _finish();
    }
  }

  Future<void> _finish() async {
    final user = context.read<UserProvider>().user!;
    String? optional(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final brandName = _name.text.trim();
    final error = await context.read<BrandProvider>().createProfile(
          BrandProfile(
            uid: user.uid,
            brandName: brandName,
            category: _category!,
            city: _city!,
            description: _description.text.trim(),
            logoUrl: optional(_logo),
            website: optional(_website),
            instagram: optional(_instagram),
            createdAt: now,
            updatedAt: now,
          ),
          panNumber: _pan.text.trim(),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isSaving = false);
      showSnack(context, error);
      return;
    }
    final onboardingError = await context
        .read<UserProvider>()
        .completeOnboarding(city: _city!, displayName: brandName);
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
          'Your business',
          'This is the name creators will see.',
          AppTextField(
            label: 'Business name',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
        ),
      1 => (
          'What kind of business?',
          'This helps us suggest creators who fit.',
          SingleSelectChips(
            options: categories.businessCategories,
            selected: _category,
            allowClear: false,
            onChanged: (value) => setState(() => _category = value),
          ),
        ),
      2 => (
          'Where are you based?',
          'Creators often look for work near them.',
          SingleSelectChips(
            options: AppConstants.cities,
            selected: _city,
            allowClear: false,
            onChanged: (value) => setState(() => _city = value),
          ),
        ),
      3 => (
          'Describe your business',
          'A couple of sentences about what you make or sell.',
          AppTextField(
            label: 'Description',
            controller: _description,
            hint: 'Modern everyday clothing brand…',
            maxLines: 5,
            maxLength: 400,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      4 => (
          'Business verification',
          'Add your PAN number so our team can review your business. '
              'Verified brands get a badge that creators trust.',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'PAN number',
                optional: true,
                controller: _pan,
                hint: '9 digits',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => Validators.pan(value, isRequired: false),
              ),
              const SizedBox(height: 14),
              Text(
                'Your PAN is kept private: only you and the CreBa Connect '
                'review team can see it. This is an in-app review, not a '
                'government verification.',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      _ => (
          'Logo and links',
          'Optional. You can add these later from your profile.',
          Column(
            children: [
              AppTextField(
                label: 'Logo image link',
                optional: true,
                controller: _logo,
                hint: 'https://',
                helper: 'Paste a link to an image. Without one, your initials are shown.',
                keyboardType: TextInputType.url,
                validator: Validators.url,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Website',
                optional: true,
                controller: _website,
                hint: 'https://',
                keyboardType: TextInputType.url,
                validator: Validators.url,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Instagram username',
                optional: true,
                controller: _instagram,
                prefixText: '@',
                textInputAction: TextInputAction.done,
              ),
            ],
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
      onSkip: _step >= 4 ? _skip : null,
      onNext: _next,
      child: Form(key: _formKey, child: content),
    );
  }
}
