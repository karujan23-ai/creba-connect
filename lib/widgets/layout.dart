import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_config.dart';

/// Centres its child and stops it growing wider than a comfortable reading
/// width, so phone layouts still look right on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.shrinkHeight = false,
  });

  final Widget child;
  final double? maxWidth;

  /// Be only as tall as [child] instead of filling the space available.
  /// Needed inside bars pinned to the bottom of a screen.
  final bool shrinkHeight;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: shrinkHeight ? 1 : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? AppConfig.maxContentWidth),
          child: child,
        ),
      );
}

/// Standard page padding. The bottom value leaves room for the floating
/// navigation bar and the system gesture area.
EdgeInsets pagePadding(BuildContext context, {double top = AppSpacing.sm}) =>
    EdgeInsets.fromLTRB(
      AppSpacing.page,
      top,
      AppSpacing.page,
      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
    );

/// A plain surface with a hairline border. The app's basic card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      side: BorderSide(color: palette.border),
    );
    return Material(
      color: palette.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A translucent, blurred surface. Used only where content scrolls
/// underneath (the bottom navigation and sticky action bars), so the user
/// keeps a sense of what is behind it.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.showTopBorder = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.78),
            border: showTopBorder
                ? Border(top: BorderSide(color: palette.border))
                : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A title above a group of content, with an optional action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.titleLarge),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: context.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 36),
                  textStyle: context.textTheme.labelMedium,
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      );
}

/// Small uppercase label, e.g. "REQUIREMENTS".
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: context.textTheme.labelSmall);
}

/// An icon followed by a short piece of text, e.g. a location or a date.
class MetaItem extends StatelessWidget {
  const MetaItem({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// A number with a label under it, used on dashboards.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              // Numbers are set in the sans face: its digits are clearer
              // than the serif's, where "1" can be read as a letter.
              child: Text(
                value,
                style: context.textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      );
}

/// Lays out [children] in equal-width columns, wrapping onto new rows.
/// The number of columns grows with the available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 150,
    this.spacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                  .floor()
                  .clamp(1, children.length.clamp(1, 6));
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in children)
                SizedBox(width: itemWidth.floorToDouble(), child: child),
            ],
          );
        },
      );
}
