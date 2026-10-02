import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/navigation.dart';
import '../../widgets/layout.dart';
import '../settings/settings_screen.dart';
import 'admin_verification_screen.dart';

/// The admin's overview: headline numbers and the queues that need action.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  static const _usersTab = 1;
  static const _contentTab = 2;
  static const _paymentsTab = 3;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final settings = context.watch<SettingsProvider>();
    final counts = admin.counts;
    final pendingBrands = admin.brandsWithStatus(VerificationStatus.pending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            tooltip: 'Refresh numbers',
            onPressed: admin.isLoadingCounts ? null : admin.refreshCounts,
            icon: admin.isLoadingCounts
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 4),
          children: [
            Text('Overview', style: context.textTheme.headlineLarge),
            const SizedBox(height: 16),
            if (admin.error != null) ...[
              Text(
                admin.error!,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: context.palette.danger),
              ),
              const SizedBox(height: 12),
            ],
            const Overline('Needs attention'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingsRow(
                    label: 'Brands waiting for verification',
                    value: '$pendingBrands',
                    onTap: () => pushScreen(context, const AdminVerificationScreen()),
                  ),
                  Divider(color: context.palette.border),
                  SettingsRow(
                    label: 'Open reports',
                    value: '${admin.openReports.length}',
                    onTap: () => onOpenTab(_contentTab),
                  ),
                  Divider(color: context.palette.border),
                  SettingsRow(
                    label: 'Promotion requests',
                    value: '${admin.promotionRequests.length}',
                    onTap: () => onOpenTab(_paymentsTab),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Overline('Analytics'),
            const SizedBox(height: 10),
            ResponsiveGrid(
              minItemWidth: 130,
              children: [
                StatTile(
                  value: '${counts.creators}',
                  label: 'Creators',
                  onTap: () => onOpenTab(_usersTab),
                ),
                StatTile(
                  value: '${counts.brands}',
                  label: 'Brands',
                  onTap: () => onOpenTab(_usersTab),
                ),
                StatTile(
                  value: '${counts.activeUsers}',
                  label: 'Active this week',
                ),
                StatTile(
                  value: '${counts.hiringPosts}',
                  label: 'Hiring posts',
                  onTap: () => onOpenTab(_contentTab),
                ),
                StatTile(
                  value: '${counts.availabilityPosts}',
                  label: 'Creator posts',
                  onTap: () => onOpenTab(_contentTab),
                ),
                StatTile(value: '${counts.applications}', label: 'Applications'),
                StatTile(
                  value: settings.money(counts.revenueNpr),
                  label: 'Revenue',
                  onTap: () => onOpenTab(_paymentsTab),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Revenue is the total of recorded payments. It stays at zero '
              'until online payment is connected.',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
