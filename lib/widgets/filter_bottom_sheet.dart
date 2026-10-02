import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'app_button.dart';
import 'dialogs.dart';

/// The frame for a filter sheet: sections of choices, with "Clear" and
/// "Show results" pinned at the bottom.
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({
    super.key,
    required this.sections,
    required this.onClear,
    required this.onApply,
    this.title = 'Filters',
  });

  final String title;
  /// Usually [FilterSection]s, but any widget (such as a switch) works.
  final List<Widget> sections;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => SheetScaffold(
        title: title,
        footer: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Clear',
                variant: AppButtonVariant.secondary,
                onPressed: onClear,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(label: 'Show results', onPressed: onApply),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: section,
              ),
          ],
        ),
      );
}

/// One titled group inside a [FilterBottomSheet].
class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textTheme.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
      );
}
