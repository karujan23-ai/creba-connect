import 'package:flutter/material.dart';

import '../models/hiring_post.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import 'badges.dart';
import 'brand_card.dart';
import 'layout.dart';
import 'price_display.dart';
import 'profile_avatar.dart';

/// A hiring opportunity in a feed. Typography and spacing carry the
/// structure; the card itself is deliberately plain.
class HiringPostCard extends StatelessWidget {
  const HiringPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.matchPercent,
    this.headerTrailing,
    this.footer,
  });

  final HiringPost post;
  final VoidCallback onTap;
  final int? matchPercent;

  /// Top-right corner, usually a "more" menu.
  final Widget? headerTrailing;

  /// Bottom row, usually action buttons or statistics.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(name: post.brandName, size: 30, square: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandNameLine(name: post.brandName, isVerified: post.brandVerified),
                    Text(
                      post.isPromoted ? 'Promoted' : Dates.ago(post.createdAt),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: post.isPromoted ? palette.accent : null,
                        fontWeight: post.isPromoted ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (post.locationLabel.isNotEmpty)
                MetaItem(icon: Icons.place_outlined, text: post.locationLabel),
              if (post.startDate != null)
                MetaItem(
                  icon: Icons.calendar_today_outlined,
                  text: Dates.short(post.startDate!),
                ),
              if (post.workType.isNotEmpty)
                MetaItem(icon: Icons.schedule_outlined, text: post.workType),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BudgetDisplay(post: post, style: context.textTheme.titleMedium),
              if (matchPercent != null) MatchBadge(percent: matchPercent!),
              if (!post.isOpen) const StatusBadge(label: 'Closed'),
              if (post.isDemo) const StatusBadge(label: 'Sample'),
            ],
          ),
          if (post.deadline != null) ...[
            const SizedBox(height: 6),
            Text(
              post.deadlinePassed
                  ? 'Applications closed ${Dates.short(post.deadline!)}'
                  : 'Apply by ${Dates.short(post.deadline!)}',
              style: context.textTheme.bodySmall,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 14),
            Divider(color: palette.border),
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}
