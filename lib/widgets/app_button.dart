import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// The one button used across the app, so every button looks and behaves
/// the same (including the loading spinner).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width.
  final bool expand;

  /// Smaller height, for buttons inside cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = switch (variant) {
      AppButtonVariant.primary => palette.onPrimary,
      AppButtonVariant.danger => palette.danger,
      _ => palette.text,
    };

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: onPressed == null ? null : foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    // While loading, taps are ignored but the button keeps its colour.
    final action = isLoading ? () {} : onPressed;
    final sizing = compact
        ? ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 14),
            ),
            textStyle: WidgetStatePropertyAll(context.textTheme.titleSmall),
            tapTargetSize: MaterialTapTargetSize.padded,
          )
        : null;

    final button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: action, style: sizing, child: child),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: action, style: sizing, child: child),
      AppButtonVariant.ghost =>
        TextButton(onPressed: action, style: sizing, child: child),
      AppButtonVariant.danger => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.danger,
            side: BorderSide(color: palette.danger.withValues(alpha: 0.4)),
          ).merge(sizing),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
