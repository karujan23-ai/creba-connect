import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'category_chip.dart';
import 'dialogs.dart';
import 'filter_bottom_sheet.dart';

/// Lets any user report a profile or post to the admins.
class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetLabel,
  });

  final String targetId;
  final TargetType targetType;
  final String targetLabel;

  static Future<void> show(
    BuildContext context, {
    required String targetId,
    required TargetType targetType,
    required String targetLabel,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => ReportSheet(
          targetId: targetId,
          targetType: targetType,
          targetLabel: targetLabel,
        ),
      );

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _description = TextEditingController();
  String? _reason;
  bool _isSending = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      showSnack(context, 'Please choose a reason.');
      return;
    }
    setState(() => _isSending = true);
    final error = await context.read<AdminProvider>().submitReport(
          targetId: widget.targetId,
          targetType: widget.targetType,
          targetLabel: widget.targetLabel,
          reason: _reason!,
          description: _description.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (showResult(context, error, success: 'Report sent. Thank you.')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
        title: 'Report',
        subtitle: '${widget.targetType.label}: ${widget.targetLabel}',
        footer: AppButton(
          label: 'Send report',
          isLoading: _isSending,
          onPressed: _submit,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSection(
              title: 'What is wrong?',
              child: SingleSelectChips(
                options: AppConstants.reportReasons,
                selected: _reason,
                onChanged: (value) => setState(() => _reason = value),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Details',
              optional: true,
              controller: _description,
              hint: 'Anything that helps us understand',
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      );
}
