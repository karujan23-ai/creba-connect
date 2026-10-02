import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand_profile.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';

/// Edit the brand profile. Verification status is not editable here; only
/// an admin can change it.
class EditBrandProfileScreen extends StatefulWidget {
  const EditBrandProfileScreen({super.key, required this.brand});

  final BrandProfile brand;

  @override
  State<EditBrandProfileScreen> createState() => _EditBrandProfileScreenState();
}

class _EditBrandProfileScreenState extends State<EditBrandProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BrandProfile _original = widget.brand;

  late final _name = TextEditingController(text: _original.brandName);
  late final _description = TextEditingController(text: _original.description);
  late final _logo = TextEditingController(text: _original.logoUrl);
  late final _website = TextEditingController(text: _original.website);
  late final _instagram = TextEditingController(text: _original.instagram);
  late String? _category = _original.category.isEmpty ? null : _original.category;
  late String? _city = _original.city.isEmpty ? null : _original.city;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [_name, _description, _logo, _website, _instagram]) {
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
    if (_category == null || _city == null) {
      showSnack(context, 'Choose a category and a city.');
      return;
    }

    final updated = BrandProfile(
      uid: _original.uid,
      brandName: _name.text.trim(),
      category: _category!,
      city: _city!,
      description: _description.text.trim(),
      logoUrl: _optional(_logo),
      website: _optional(_website),
      instagram: _optional(_instagram),
      verificationStatus: _original.verificationStatus,
      createdAt: _original.createdAt,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();
    final error = await context.read<BrandProvider>().updateProfile(updated);
    if (error == null) {
      await userProvider.updateBasics(displayName: updated.brandName, city: updated.city);
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
                label: 'Business name',
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.minLength(value, 2, 'Business name'),
              ),
              gap,
              AppTextField(
                label: 'Description',
                controller: _description,
                maxLines: 4,
                maxLength: 400,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.minLength(value, 20, 'Description'),
              ),
              gap,
              const FieldLabel('Business category'),
              SingleSelectChips(
                options: categories.businessCategories,
                selected: _category,
                allowClear: false,
                onChanged: (value) => setState(() => _category = value),
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
                label: 'Website',
                optional: true,
                controller: _website,
                hint: 'https://',
                keyboardType: TextInputType.url,
                validator: Validators.url,
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
                label: 'Logo image link',
                optional: true,
                controller: _logo,
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
