import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_palette.dart';

/// A small coloured label, e.g. "Shortlisted" or "Pending review".
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});

  final String label;

  /// Defaults to a neutral grey.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelMedium?.copyWith(
          color: tone,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// [StatusBadge] coloured for an application's stage.
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (status) {
      ApplicationStatus.applied => palette.textMuted,
      ApplicationStatus.shortlisted => palette.verified,
      ApplicationStatus.discussion => palette.warning,
      ApplicationStatus.selected => palette.success,
      ApplicationStatus.rejected => palette.danger,
      ApplicationStatus.withdrawn => palette.textFaint,
    };
    return StatusBadge(label: status.label, color: color);
  }
}

/// [StatusBadge] coloured for a brand's verification state.
class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (status) {
      VerificationStatus.pending => palette.warning,
      VerificationStatus.verified => palette.verified,
      VerificationStatus.rejected => palette.danger,
    };
    return StatusBadge(label: status.label, color: color);
  }
}

/// The tick shown next to a verified brand. "Business Verified" means an
/// admin of this app approved the brand; it is not a government check.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.showLabel = false, this.size = 16});

  final bool showLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.verified;
    final icon = Icon(
      Icons.verified,
      size: size,
      color: color,
      semanticLabel: 'Business Verified',
    );
    if (!showLabel) return Tooltip(message: 'Business Verified', child: icon);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          'Business Verified',
          style: context.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// "92% match" — the Best Fit score.
class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: '$percent% match', color: context.palette.accent);
}
