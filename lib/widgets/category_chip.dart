import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A pill-shaped label. Tappable when [onTap] is given.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isChoice = onTap != null;
    final background = selected
        ? palette.primary
        : (isChoice ? palette.surface : palette.surfaceAlt);
    final foreground = selected ? palette.onPrimary : palette.text;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: isChoice ? 10 : 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: selected
              ? palette.primary
              : (isChoice ? palette.border : Colors.transparent),
        ),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontSize: isChoice ? 13.5 : 12.5,
        ),
      ),
    );

    if (!isChoice) return chip;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

/// A read-only row of chips that wraps onto new lines.
class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final label in labels) CategoryChip(label: label)],
      );
}

/// Lets the user pick any number of [options].
class MultiSelectChips extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            CategoryChip(
              label: option,
              selected: selected.contains(option),
              onTap: () {
                final next = {...selected};
                if (!next.remove(option)) next.add(option);
                onChanged(next);
              },
            ),
        ],
      );
}

/// Lets the user pick one of [options]. Tapping the chosen one again
/// clears it when [allowClear] is true.
class SingleSelectChips extends StatelessWidget {
  const SingleSelectChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowClear = true,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            CategoryChip(
              label: option,
              selected: option == selected,
              onTap: () {
                if (option == selected) {
                  if (allowClear) onChanged(null);
                } else {
                  onChanged(option);
                }
              },
            ),
        ],
      );
}
