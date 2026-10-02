import 'package:flutter/material.dart';

import '../models/creator_profile.dart';
import '../theme/app_palette.dart';
import 'badges.dart';
import 'layout.dart';
import 'price_display.dart';
import 'profile_avatar.dart';

/// A creator in a list: photo, name, what they do, where, and their rate.
class CreatorCard extends StatelessWidget {
  const CreatorCard({
    super.key,
    required this.creator,
    required this.onTap,
    this.matchPercent,
    this.trailing,
  });

  final CreatorProfile creator;
  final VoidCallback onTap;

  /// Best Fit score, shown when given.
  final int? matchPercent;

  /// Usually a save button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(name: creator.fullName, imageUrl: creator.photoUrl, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
                if (creator.creatorTypes.isNotEmpty)
                  Text(
                    creator.typeLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (creator.niches.isNotEmpty) creator.niches.take(3).join(' · '),
                    if (creator.city.isNotEmpty) creator.city,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AvailabilityDot(isAvailable: creator.isAvailable),
                    if (creator.startingRate != null)
                      PriceDisplay(
                        amount: creator.startingRate!,
                        prefix: 'From',
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    if (matchPercent != null) MatchBadge(percent: matchPercent!),
                    if (creator.isBoosted)
                      StatusBadge(label: 'Boosted', color: palette.accent),
                    if (creator.isDemo) const StatusBadge(label: 'Sample'),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A narrow creator card for horizontal lists on the home screen.
class CreatorMiniCard extends StatelessWidget {
  const CreatorMiniCard({
    super.key,
    required this.creator,
    required this.onTap,
    this.matchPercent,
  });

  final CreatorProfile creator;
  final VoidCallback onTap;
  final int? matchPercent;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 164,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(name: creator.fullName, imageUrl: creator.photoUrl, size: 44),
              const SizedBox(height: 12),
              Text(
                creator.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                creator.creatorTypes.isEmpty ? 'Creator' : creator.creatorTypes.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              ),
              const Spacer(),
              if (matchPercent != null)
                MatchBadge(percent: matchPercent!)
              else
                Text(
                  creator.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      );
}

class _AvailabilityDot extends StatelessWidget {
  const _AvailabilityDot({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isAvailable ? palette.success : palette.textFaint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable ? 'Available' : 'Unavailable',
          style: context.textTheme.bodySmall?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
