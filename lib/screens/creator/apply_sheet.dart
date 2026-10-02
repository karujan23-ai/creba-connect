import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hiring_post.dart';
import '../../providers/application_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dialogs.dart';

/// The form a creator fills in to apply to an opportunity.
/// Submitting creates the application document in Firestore.
class ApplySheet extends StatefulWidget {
  const ApplySheet({super.key, required this.post});

  final HiringPost post;

  static Future<void> show(BuildContext context, HiringPost post) =>
      showAppSheet<void>(context, builder: (_) => ApplySheet(post: post));

  @override
  State<ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<ApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _rate = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _message.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    final error = await context.read<ApplicationProvider>().apply(
          post: widget.post,
          creatorName: context.read<UserProvider>().user!.displayName,
          message: _message.text.trim(),
          proposedRate: Money.parse(_rate.text),
        );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (showResult(context, error, success: 'Application sent.')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
        title: 'Apply',
        subtitle: '${widget.post.title} · ${widget.post.brandName}',
        footer: AppButton(
          label: 'Send application',
          isLoading: _isSending,
          onPressed: _submit,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Message to the brand',
                controller: _message,
                hint: 'Why you are a good fit, and any relevant past work',
                maxLines: 4,
                maxLength: 600,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.minLength(value, 10, 'Message'),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Your rate for this job',
                optional: true,
                controller: _rate,
                prefixText: 'NPR ',
                hint: '10,000',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.amount(value, isRequired: false),
              ),
            ],
          ),
        ),
      );
}
