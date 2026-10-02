import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/availability_post.dart';
import '../../providers/availability_provider.dart';
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

/// Create a new availability post, or edit [post] when one is given.
class AvailabilityFormScreen extends StatefulWidget {
  const AvailabilityFormScreen({super.key, this.post});

  final AvailabilityPost? post;

  @override
  State<AvailabilityFormScreen> createState() => _AvailabilityFormScreenState();
}

class _AvailabilityFormScreenState extends State<AvailabilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.post?.title);
  late final _rate = TextEditingController(
    text: widget.post?.rateFrom?.round().toString(),
  );
  late final _note = TextEditingController(text: widget.post?.note);
  late Set<String> _niches = {...?widget.post?.niches};
  late Set<String> _workTypes = {...?widget.post?.workTypes};
  late String? _city = widget.post?.city;
  late DateTime? _from = widget.post?.availableFrom;
  late DateTime? _to = widget.post?.availableTo;
  bool _isSaving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    // A new post starts from the creator's profile, so there is less to type.
    if (!_isEditing) {
      final profile = context.read<CreatorProvider>().myProfile;
      if (profile != null) {
        _niches = {...profile.niches.take(3)};
        _city = profile.city.isEmpty ? null : profile.city;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _problem() {
    if (_city == null) return 'Choose a city.';
    if (_from == null || _to == null) return 'Choose both dates.';
    if (_to!.isBefore(_from!)) return 'The end date must be after the start date.';
    if (_workTypes.isEmpty) return 'Choose at least one type of work.';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final problem = _problem();
    if (problem != null) {
      showSnack(context, problem);
      return;
    }

    final user = context.read<UserProvider>().user!;
    final provider = context.read<AvailabilityProvider>();
    final now = DateTime.now();
    final post = AvailabilityPost(
      id: widget.post?.id ?? '',
      creatorId: user.uid,
      creatorName: user.displayName,
      title: _title.text.trim(),
      niches: _niches.toList(),
      city: _city!,
      availableFrom: _from!,
      availableTo: _to!,
      workTypes: _workTypes.toList(),
      rateFrom: Money.parse(_rate.text),
      note: _note.text.trim(),
      isActive: widget.post?.isActive ?? true,
      createdAt: widget.post?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    final error =
        _isEditing ? await provider.updatePost(post) : await provider.createPost(post);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (showResult(context, error, success: _isEditing ? 'Post updated.' : 'Post created.')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    const gap = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit post' : 'New availability post')),
      body: ContentWidth(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: pagePadding(context, top: 12),
            children: [
              AppTextField(
                label: 'Title',
                controller: _title,
                hint: 'Available for Fashion Shoots',
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.minLength(value, 5, 'Title'),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DateField(
                      label: 'From',
                      value: _from,
                      onChanged: (date) => setState(() => _from = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DateField(
                      label: 'To',
                      value: _to,
                      firstDate: _from,
                      onChanged: (date) => setState(() => _to = date),
                    ),
                  ),
                ],
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
              const FieldLabel('Type of work'),
              MultiSelectChips(
                options: AppConstants.workTypes,
                selected: _workTypes,
                onChanged: (value) => setState(() => _workTypes = value),
              ),
              gap,
              const FieldLabel('Niches', optional: true),
              MultiSelectChips(
                options: categories.niches,
                selected: _niches,
                onChanged: (value) => setState(() => _niches = value),
              ),
              gap,
              AppTextField(
                label: 'Rate from',
                optional: true,
                controller: _rate,
                prefixText: 'NPR ',
                hint: '7,000',
                keyboardType: TextInputType.number,
                validator: (value) => Validators.amount(value, isRequired: false),
              ),
              gap,
              AppTextField(
                label: 'Note',
                optional: true,
                controller: _note,
                hint: 'Anything brands should know',
                maxLines: 3,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Publish post',
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
