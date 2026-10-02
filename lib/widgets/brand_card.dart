import 'package:flutter/material.dart';

import '../models/brand_profile.dart';
import '../theme/app_palette.dart';
import 'badges.dart';
import 'layout.dart';
import 'profile_avatar.dart';

/// A brand in a list: logo, name, verified tick, category and city.
class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.brand, required this.onTap, this.trailing});

  final BrandProfile brand;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Row(
          children: [
            ProfileAvatar(
              name: brand.brandName,
              imageUrl: brand.logoUrl,
              size: 48,
              square: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandNameLine(
                    name: brand.brandName,
                    isVerified: brand.isVerified,
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [brand.category, brand.city].where((v) => v.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (brand.isDemo) const StatusBadge(label: 'Sample'),
            ?trailing,
          ],
        ),
      );
}

/// A narrow brand card for horizontal lists on the home screen.
class BrandMiniCard extends StatelessWidget {
  const BrandMiniCard({super.key, required this.brand, required this.onTap});

  final BrandProfile brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: brand.brandName,
                imageUrl: brand.logoUrl,
                size: 44,
                square: true,
              ),
              const Spacer(),
              BrandNameLine(
                name: brand.brandName,
                isVerified: brand.isVerified,
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                brand.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

/// A brand name followed by the verified tick when the brand is verified.
class BrandNameLine extends StatelessWidget {
  const BrandNameLine({
    super.key,
    required this.name,
    required this.isVerified,
    this.style,
  });

  final String name;
  final bool isVerified;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style ?? context.textTheme.titleSmall,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 5),
            VerifiedBadge(size: (style?.fontSize ?? 14) + 1),
          ],
        ],
      );
}
