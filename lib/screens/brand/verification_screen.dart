import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/brand_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';

/// Where a brand sees its verification status and submits its PAN details.
///
/// "Business Verified" here means an admin of this app reviewed the details.
/// The PAN is not checked against any government system.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _pan = TextEditingController(
    text: context.read<BrandProvider>().myVerification?.panNumber,
  );
  late final _document = TextEditingController(
    text: context.read<BrandProvider>().myVerification?.panDocumentUrl,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _pan.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final document = _document.text.trim();
    final error = await context.read<BrandProvider>().submitVerification(
          panNumber: _pan.text.trim(),
          panDocumentUrl: document.isEmpty ? null : document,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    showResult(context, error, success: 'Submitted for review.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();
    final brand = provider.myBrand;
    final verification = provider.myVerification;
    final palette = context.palette;

    if (brand == null) {
      return Scaffold(appBar: AppBar(), body: const LoadingState());
    }
    final status = brand.verificationStatus;
    final explanation = switch (status) {
      VerificationStatus.verified =>
        'Your business is verified. Creators see a badge next to your name.',
      VerificationStatus.rejected =>
        'Your last submission was not approved. Check the details below and '
            'submit again.',
      VerificationStatus.pending => (verification?.hasPan ?? false)
          ? 'Your details are waiting for review by the CreBa Connect team.'
          : 'Add your PAN number to be reviewed.',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Business verification')),
      body: ContentWidth(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: pagePadding(context, top: 12),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isVerified)
                      const VerifiedBadge(showLabel: true)
                    else
                      VerificationStatusBadge(status: status),
                    const SizedBox(height: 10),
                    Text(explanation, style: context.textTheme.bodyMedium),
                    if (status == VerificationStatus.rejected &&
                        verification?.rejectionReason != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Reason: ${verification!.rejectionReason}',
                        style: context.textTheme.bodyMedium?.copyWith(color: palette.danger),
                      ),
                    ],
                    if (verification?.submittedAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Submitted ${Dates.full(verification!.submittedAt!)}',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppTextField(
                label: 'PAN number',
                controller: _pan,
                hint: '9 digits',
                keyboardType: TextInputType.number,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.pan,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'PAN document link',
                optional: true,
                controller: _document,
                hint: 'https://',
                helper: 'A link to a photo or scan of your PAN certificate, '
                    'for example on Google Drive.',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                validator: Validators.url,
              ),
              const SizedBox(height: 14),
              Text(
                'Only you and the CreBa Connect review team can see these '
                'details. This is an in-app review, not a government '
                'verification.',
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: status == VerificationStatus.verified
                    ? 'Update details'
                    : 'Submit for review',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
              if (status == VerificationStatus.verified) ...[
                const SizedBox(height: 10),
                Text(
                  'Changing your details sends your business back for review.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
