import 'package:flutter/material.dart';

import '../models/job_application.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import 'badges.dart';
import 'layout.dart';
import 'price_display.dart';
import 'profile_avatar.dart';

/// One application in a list. A brand sees who applied; a creator sees what
/// they applied to.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    required this.forBrand,
    this.onTap,
    this.footer,
  });

  final JobApplication application;

  /// True on the brand's screens, false on the creator's.
  final bool forBrand;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final heading = forBrand ? application.creatorName : application.jobTitle;
    final subheading = forBrand ? application.jobTitle : application.brandName;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: forBrand ? application.creatorName : application.brandName,
                size: 40,
                square: !forBrand,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium,
                    ),
                    Text(
                      subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ApplicationStatusBadge(status: application.status),
            ],
          ),
          if (application.message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              application.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (application.proposedRate != null)
                Expanded(
                  child: PriceDisplay(
                    amount: application.proposedRate!,
                    prefix: 'Proposed',
                  ),
                )
              else
                const Spacer(),
              Text(Dates.ago(application.createdAt), style: context.textTheme.bodySmall),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Divider(color: palette.border),
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}
