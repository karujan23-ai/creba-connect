import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/formatters.dart';

/// A label above any form control, matching [AppTextField]'s label.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false, this.hint});

  final String text;
  final bool optional;

  /// Extra guidance shown under the label.
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(child: Text(text, style: context.textTheme.titleSmall)),
                if (optional) ...[
                  const SizedBox(width: 6),
                  Text('Optional', style: context.textTheme.bodySmall),
                ],
              ],
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(hint!, style: context.textTheme.bodySmall),
              ),
          ],
        ),
      );
}

/// A field that opens the date picker when tapped.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.optional = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Earliest selectable day. Defaults to today.
  final DateTime? firstDate;
  final bool optional;

  Future<void> _pick(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = firstDate ?? today;
    final initial = value != null && !value!.isBefore(first) ? value! : first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, optional: optional),
        Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            side: BorderSide(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _pick(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 17, color: palette.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value == null ? 'Choose a date' : Dates.full(value!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: value == null ? palette.textFaint : palette.text,
                      ),
                    ),
                  ),
                  if (value != null && optional)
                    GestureDetector(
                      onTap: () => onChanged(null),
                      child: Icon(Icons.close, size: 18, color: palette.textMuted),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Splits a multi-line text box into a clean list: one item per line,
/// with blank lines and leading bullets removed.
List<String> linesToList(String text) => text
    .split('\n')
    .map((line) => line.replaceFirst(RegExp(r'^\s*[•\-*]\s*'), '').trim())
    .where((line) => line.isNotEmpty)
    .toList();

/// A bulleted list of short lines, e.g. requirements or deliverables.
class BulletList extends StatelessWidget {
  const BulletList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.palette.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: context.textTheme.bodyLarge)),
                ],
              ),
            ),
        ],
      );
}
