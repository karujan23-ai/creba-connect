import 'package:flutter/material.dart';

import '../models/availability_post.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import 'badges.dart';
import 'layout.dart';
import 'price_display.dart';
import 'profile_avatar.dart';

/// A creator's availability post in a list.
class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    super.key,
    required this.post,
    this.onTap,
    this.showCreator = true,
    this.footer,
  });

  final AvailabilityPost post;
  final VoidCallback? onTap;

  /// Hidden on the creator's own list, where every post is theirs.
  final bool showCreator;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCreator) ...[
            Row(
              children: [
                ProfileAvatar(name: post.creatorName, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.creatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                ),
                if (post.isDemo) const StatusBadge(label: 'Sample'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge,
                ),
              ),
              if (!showCreator) ...[
                const SizedBox(width: 10),
                StatusBadge(
                  label: post.hasEnded
                      ? 'Ended'
                      : (post.isActive ? 'Active' : 'Paused'),
                  color: post.isActive && !post.hasEnded ? palette.success : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              MetaItem(
                icon: Icons.calendar_today_outlined,
                text: Dates.range(post.availableFrom, post.availableTo),
              ),
              if (post.city.isNotEmpty)
                MetaItem(icon: Icons.place_outlined, text: post.city),
            ],
          ),
          if (post.workTypes.isNotEmpty || post.niches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [...post.niches, ...post.workTypes].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
          if (post.rateFrom != null) ...[
            const SizedBox(height: 12),
            PriceDisplay(
              amount: post.rateFrom!,
              currency: post.currency,
              prefix: 'From',
              style: context.textTheme.titleMedium,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 14),
            Divider(color: palette.border),
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}
