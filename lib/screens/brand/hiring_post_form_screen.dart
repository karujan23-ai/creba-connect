import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/app_config.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';

/// "Hire a Creator": create a new hiring post, or edit [post] when given.
class HiringPostFormScreen extends StatefulWidget {
  const HiringPostFormScreen({super.key, this.post});

  final HiringPost? post;

  @override
  State<HiringPostFormScreen> createState() => _HiringPostFormScreenState();
}

class _HiringPostFormScreenState extends State<HiringPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final HiringPost? _original = widget.post;

  late final _title = TextEditingController(text: _original?.title);
  late final _description = TextEditingController(text: _original?.description);
  late final _duration = TextEditingController(text: _original?.duration);
  late final _budgetMin = TextEditingController(
    text: _original?.budgetMin?.round().toString(),
  );
  late final _budgetMax = TextEditingController(
    text: _original?.budgetMax?.round().toString(),
  );
  late final _creatorsNeeded = TextEditingController(
    text: '${_original?.creatorsNeeded ?? 1}',
  );
  late final _requirements = TextEditingController(
    text: _original?.requirements.join('\n'),
  );
  late final _deliverables = TextEditingController(
    text: _original?.deliverables.join('\n'),
  );
  late final _image = TextEditingController(text: _original?.imageUrl);

  late Set<String> _creatorTypes = {...?_original?.creatorTypes};
  late Set<String> _niches = {...?_original?.niches};
  late String? _city = _original?.city;
  late bool _isRemote = _original?.isRemote ?? false;
  late String? _workType = _original?.workType;
  late DateTime? _startDate = _original?.startDate;
  late DateTime? _deadline = _original?.deadline;
  late BudgetType _budgetType = _original?.budgetType ?? BudgetType.fixed;
  late Currency _currency = _original?.currency ?? Currency.npr;
  late String _contact = _original?.contactPreference ?? AppConstants.contactPreferences.first;
  bool _isSaving = false;

  bool get _isEditing => _original != null;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) {
      final brand = context.read<BrandProvider>().myBrand;
      _city = (brand?.city.isEmpty ?? true) ? null : brand!.city;
      _niches = {...?AppConstants.categoryToNiches[brand?.category]?.take(2)};
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _duration,
      _budgetMin,
      _budgetMax,
      _creatorsNeeded,
      _requirements,
      _deliverables,
      _image,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Checks that cannot be expressed as a single text-field validator.
  String? _problem() {
    if (_creatorTypes.isEmpty) return 'Choose the kind of creator you need.';
    if (_workType == null) return 'Choose a work type.';
    if (_city == null && !_isRemote) return 'Choose a location, or mark the job as remote.';
    if (_startDate == null) return 'Choose the date of the work.';
    if (_deadline != null && _deadline!.isAfter(_startDate!)) {
      return 'The application deadline must be on or before the work date.';
    }
    if (_budgetType == BudgetType.range) {
      final min = Money.parse(_budgetMin.text);
      final max = Money.parse(_budgetMax.text);
      if (min != null && max != null && max <= min) {
        return 'The maximum budget must be higher than the minimum.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showSnack(context, 'Please fix the highlighted fields.');
      return;
    }
    final problem = _problem();
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    final brand = context.read<BrandProvider>().myBrand;
    if (brand == null) {
      showSnack(context, 'Your brand profile is still loading. Please try again.');
      return;
    }

    final hasBudget = _budgetType != BudgetType.negotiable;
    final imageUrl = _image.text.trim();
    final now = DateTime.now();
    final post = HiringPost(
      id: _original?.id ?? '',
      brandId: brand.uid,
      brandName: brand.brandName,
      brandVerified: brand.isVerified,
      title: _title.text.trim(),
      description: _description.text.trim(),
      creatorTypes: _creatorTypes.toList(),
      niches: _niches.toList(),
      city: _city ?? '',
      isRemote: _isRemote,
      workType: _workType!,
      startDate: _startDate,
      duration: _duration.text.trim(),
      budgetType: _budgetType,
      budgetMin: hasBudget ? Money.parse(_budgetMin.text) : null,
      budgetMax: _budgetType == BudgetType.range ? Money.parse(_budgetMax.text) : null,
      currency: _currency,
      creatorsNeeded: int.parse(_creatorsNeeded.text.trim()),
      requirements: linesToList(_requirements.text),
      deliverables: linesToList(_deliverables.text),
      deadline: _deadline,
      contactPreference: _contact,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      status: _original?.status ?? PostStatus.open,
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    final provider = context.read<HiringPostProvider>();
    final error =
        _isEditing ? await provider.updatePost(post) : await provider.createPost(post);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (showResult(
      context,
      error,
      success: _isEditing ? 'Opportunity updated.' : 'Opportunity published.',
    )) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    const gap = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit opportunity' : 'Hire a creator')),
      body: ContentWidth(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: pagePadding(context, top: 12),
            children: [
              AppTextField(
                label: 'Title',
                controller: _title,
                hint: 'Fashion Model Needed',
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.minLength(value, 5, 'Title'),
              ),
              gap,
              AppTextField(
                label: 'Description',
                controller: _description,
                hint: 'What the campaign is about and what you expect',
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.minLength(value, 20, 'Description'),
              ),
              gap,
              const FieldLabel('Creator type'),
              MultiSelectChips(
                options: categories.creatorTypes,
                selected: _creatorTypes,
                onChanged: (value) => setState(() => _creatorTypes = value),
              ),
              gap,
              const FieldLabel('Niches', optional: true),
              MultiSelectChips(
                options: categories.niches,
                selected: _niches,
                onChanged: (value) => setState(() => _niches = value),
              ),
              gap,
              const FieldLabel('Work type'),
              SingleSelectChips(
                options: AppConstants.workTypes,
                selected: _workType,
                allowClear: false,
                onChanged: (value) => setState(() => _workType = value),
              ),
              gap,
              const FieldLabel('Location'),
              SingleSelectChips(
                options: AppConstants.cities,
                selected: _city,
                onChanged: (value) => setState(() => _city = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Can be done remotely', style: context.textTheme.bodyLarge),
                value: _isRemote,
                onChanged: (value) => setState(() => _isRemote = value),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DateField(
                      label: 'Work date',
                      value: _startDate,
                      onChanged: (date) => setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DateField(
                      label: 'Apply by',
                      optional: true,
                      value: _deadline,
                      onChanged: (date) => setState(() => _deadline = date),
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'Duration',
                      optional: true,
                      controller: _duration,
                      hint: '1 day',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Creators',
                      controller: _creatorsNeeded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => Validators.wholeNumber(value, max: 100),
                    ),
                  ),
                ],
              ),
              gap,
              const FieldLabel('Budget'),
              SingleSelectChips(
                options: [for (final type in BudgetType.values) type.label],
                selected: _budgetType.label,
                allowClear: false,
                onChanged: (label) => setState(
                  () => _budgetType =
                      BudgetType.values.firstWhere((type) => type.label == label),
                ),
              ),
              if (_budgetType != BudgetType.negotiable) ...[
                const SizedBox(height: 16),
                SingleSelectChips(
                  options: [for (final currency in Currency.values) currency.code],
                  selected: _currency.code,
                  allowClear: false,
                  onChanged: (code) =>
                      setState(() => _currency = Currency.fromCode(code)),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: _budgetType == BudgetType.range ? 'Minimum' : 'Amount',
                        controller: _budgetMin,
                        prefixText: '${_currency.code} ',
                        keyboardType: TextInputType.number,
                        validator: Validators.amount,
                      ),
                    ),
                    if (_budgetType == BudgetType.range) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Maximum',
                          controller: _budgetMax,
                          prefixText: '${_currency.code} ',
                          keyboardType: TextInputType.number,
                          validator: Validators.amount,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Shown to creators in their chosen currency. Converted amounts '
                  'use a fixed rate (1 USD ≈ NPR ${AppConfig.nprPerUsd.round()}) '
                  'and are marked as approximate.',
                  style: context.textTheme.bodySmall,
                ),
              ],
              gap,
              AppTextField(
                label: 'Requirements',
                optional: true,
                controller: _requirements,
                hint: 'One per line\nFashion experience\nComfortable on camera',
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              gap,
              AppTextField(
                label: 'Deliverables',
                optional: true,
                controller: _deliverables,
                hint: 'One per line\n4 hour shoot\n3 outfits',
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              gap,
              const FieldLabel('How should creators contact you?'),
              SingleSelectChips(
                options: AppConstants.contactPreferences,
                selected: _contact,
                allowClear: false,
                onChanged: (value) => setState(() => _contact = value!),
              ),
              gap,
              AppTextField(
                label: 'Image link',
                optional: true,
                controller: _image,
                hint: 'https://',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                validator: Validators.url,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Publish opportunity',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
