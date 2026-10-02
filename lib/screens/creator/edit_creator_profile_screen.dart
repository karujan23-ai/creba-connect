import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../providers/category_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';

/// Edit every part of a creator profile. Saving UPDATEs
/// `creatorProfiles/{uid}` in Firestore.
class EditCreatorProfileScreen extends StatefulWidget {
  const EditCreatorProfileScreen({super.key, required this.profile});

  final CreatorProfile profile;

  @override
  State<EditCreatorProfileScreen> createState() => _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState extends State<EditCreatorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CreatorProfile _original = widget.profile;

  late final _name = TextEditingController(text: _original.fullName);
  late final _bio = TextEditingController(text: _original.bio);
  late final _rate = TextEditingController(
    text: _original.startingRate?.round().toString(),
  );
  late final _skills = TextEditingController(text: _original.skills.join(', '));
  late final _collaborations = TextEditingController(
    text: _original.previousCollaborations.join('\n'),
  );
  late final _instagram = TextEditingController(text: _original.instagram);
  late final _tiktok = TextEditingController(text: _original.tiktok);
  late final _youtube = TextEditingController(text: _original.youtube);
  late final _portfolio = TextEditingController(text: _original.portfolioUrl);
  late final _photo = TextEditingController(text: _original.photoUrl);

  late Set<String> _types = {..._original.creatorTypes};
  late Set<String> _niches = {..._original.niches};
  late Set<String> _languages = {..._original.languages};
  late Set<String> _workTypes = {..._original.workTypes};
  late String? _city = _original.city.isEmpty ? null : _original.city;
  late String? _gender = _original.gender;
  late String? _ageRange = _original.ageRange;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _bio,
      _rate,
      _skills,
      _collaborations,
      _instagram,
      _tiktok,
      _youtube,
      _portfolio,
      _photo,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showSnack(context, 'Please fix the highlighted fields.');
      return;
    }
    if (_types.isEmpty || _niches.isEmpty || _city == null) {
      showSnack(context, 'Choose at least one creator type, one niche and a city.');
      return;
    }

    final updated = CreatorProfile(
      uid: _original.uid,
      fullName: _name.text.trim(),
      creatorTypes: _types.toList(),
      niches: _niches.toList(),
      city: _city!,
      bio: _bio.text.trim(),
      photoUrl: _optional(_photo),
      gender: _gender,
      ageRange: _ageRange,
      languages: _languages.toList(),
      skills: _skills.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList(),
      instagram: _optional(_instagram),
      tiktok: _optional(_tiktok),
      youtube: _optional(_youtube),
      portfolioUrl: _optional(_portfolio),
      startingRate: Money.parse(_rate.text),
      workTypes: _workTypes.toList(),
      isAvailable: _original.isAvailable,
      previousCollaborations: linesToList(_collaborations.text),
      createdAt: _original.createdAt,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();
    final error = await context.read<CreatorProvider>().updateProfile(updated);
    if (error == null) {
      // Keeps the name shown in chats and greetings in step with the profile.
      await userProvider.updateBasics(displayName: updated.fullName, city: updated.city);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (showResult(context, error, success: 'Profile updated.')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    const gap = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ContentWidth(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: pagePadding(context, top: 12),
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.minLength(value, 2, 'Full name'),
              ),
              gap,
              AppTextField(
                label: 'Bio',
                controller: _bio,
                maxLines: 4,
                maxLength: 400,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.minLength(value, 20, 'Bio'),
              ),
              gap,
              const FieldLabel('Creator type'),
              MultiSelectChips(
                options: categories.creatorTypes,
                selected: _types,
                onChanged: (value) => setState(() => _types = value),
              ),
              gap,
              const FieldLabel('Niches'),
              MultiSelectChips(
                options: categories.niches,
                selected: _niches,
                onChanged: (value) => setState(() => _niches = value),
              ),
              gap,
              const FieldLabel('City'),
              SingleSelectChips(
                options: AppConstants.cities,
                selected: _city,
                allowClear: false,
                onChanged: (value) => setState(() => _city = value),
              ),
              gap,
              AppTextField(
                label: 'Starting rate',
                optional: true,
                controller: _rate,
                prefixText: 'NPR ',
                hint: '5,000',
                keyboardType: TextInputType.number,
                validator: (value) => Validators.amount(value, isRequired: false),
              ),
              gap,
              const FieldLabel('Available for', optional: true),
              MultiSelectChips(
                options: AppConstants.workTypes,
                selected: _workTypes,
                onChanged: (value) => setState(() => _workTypes = value),
              ),
              gap,
              const FieldLabel('Languages', optional: true),
              MultiSelectChips(
                options: AppConstants.languages,
                selected: _languages,
                onChanged: (value) => setState(() => _languages = value),
              ),
              gap,
              AppTextField(
                label: 'Skills',
                optional: true,
                controller: _skills,
                hint: 'Runway, Lookbook shoots, Short-form video',
                helper: 'Separate with commas',
                textCapitalization: TextCapitalization.sentences,
              ),
              gap,
              AppTextField(
                label: 'Previous collaborations',
                optional: true,
                controller: _collaborations,
                hint: 'One per line',
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              gap,
              const FieldLabel('Gender', optional: true),
              SingleSelectChips(
                options: AppConstants.genders,
                selected: _gender,
                onChanged: (value) => setState(() => _gender = value),
              ),
              gap,
              const FieldLabel('Age range', optional: true),
              SingleSelectChips(
                options: AppConstants.ageRanges,
                selected: _ageRange,
                onChanged: (value) => setState(() => _ageRange = value),
              ),
              gap,
              AppTextField(
                label: 'Instagram username',
                optional: true,
                controller: _instagram,
                prefixText: '@',
              ),
              gap,
              AppTextField(
                label: 'TikTok username',
                optional: true,
                controller: _tiktok,
                prefixText: '@',
              ),
              gap,
              AppTextField(
                label: 'YouTube channel',
                optional: true,
                controller: _youtube,
                prefixText: '@',
              ),
              gap,
              AppTextField(
                label: 'Portfolio link',
                optional: true,
                controller: _portfolio,
                hint: 'https://',
                keyboardType: TextInputType.url,
                validator: Validators.url,
              ),
              gap,
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
              const SizedBox(height: 28),
              AppButton(label: 'Save changes', isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
