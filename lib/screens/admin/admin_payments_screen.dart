import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/promotion.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';

/// Admin: promotion requests, payment records and subscriptions.
///
/// No online payment is connected, so the Payments list is expected to be
/// empty. Approving a promotion here is a manual action that collects no
/// money and creates no payment record.
class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Promotions (${admin.promotionRequests.length})'),
              Tab(text: 'Payments (${admin.payments.length})'),
              Tab(text: 'Subscriptions (${admin.subscriptions.length})'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_Promotions(), _Payments(), _Subscriptions()],
        ),
      ),
    );
  }
}

class _Promotions extends StatelessWidget {
  const _Promotions();

  @override
  Widget build(BuildContext context) {
    final promotions = context.watch<AdminProvider>().promotions;
    if (promotions.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        title: 'No promotion requests',
        message: 'Requests from brands and creators will appear here.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: promotions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _PromotionCard(
          key: ValueKey(promotions[index].id),
          promotion: promotions[index],
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({super.key, required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final admin = context.read<AdminProvider>();
    final settings = context.watch<SettingsProvider>();
    final statusColor = switch (promotion.status) {
      PromotionStatus.requested => palette.warning,
      PromotionStatus.active => palette.success,
      PromotionStatus.expired => palette.textMuted,
      PromotionStatus.rejected => palette.danger,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promotion.targetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: promotion.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${promotion.targetType == TargetType.hiringPost ? 'Hiring post' : 'Creator profile'}'
            ' · requested by ${promotion.ownerName}',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(
            '${promotion.packageDays} days · ${settings.money(promotion.priceNpr)}',
            style: context.textTheme.titleSmall,
          ),
          if (promotion.endsAt != null)
            Text(
              'Ends ${Dates.full(promotion.endsAt!)}',
              style: context.textTheme.bodySmall,
            ),
          if (promotion.status == PromotionStatus.requested) ...[
            const SizedBox(height: 12),
            Divider(color: palette.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.secondary,
                    compact: true,
                    onPressed: () async {
                      final error = await admin.rejectPromotion(promotion);
                      if (context.mounted) {
                        showResult(context, error, success: 'Request declined.');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Approve manually',
                    compact: true,
                    onPressed: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Approve without payment?',
                        message: 'This activates the promotion for '
                            '${promotion.packageDays} days. No payment is '
                            'collected or recorded.',
                        confirmLabel: 'Approve',
                      );
                      if (!confirmed) return;
                      final error = await admin.approvePromotion(promotion);
                      if (context.mounted) {
                        showResult(context, error, success: 'Promotion activated.');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Payments extends StatelessWidget {
  const _Payments();

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<AdminProvider>().payments;
    if (payments.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No payments recorded',
        message: 'Online payment is not connected yet. Once it is, each '
            'completed payment will be listed here.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final payment = payments[index];
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.purpose, style: context.textTheme.titleSmall),
                      Text(
                        '${payment.provider} · ${Dates.full(payment.createdAt)}',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.format(payment.amount, Currency.fromCode(payment.currency)),
                      style: context.textTheme.titleSmall,
                    ),
                    Text(payment.status, style: context.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Subscriptions extends StatelessWidget {
  const _Subscriptions();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final subscriptions = admin.subscriptions;
    if (subscriptions.isEmpty) {
      return const EmptyState(
        icon: Icons.workspace_premium_outlined,
        title: 'No subscriptions',
        message: 'Everyone is on the Free plan. Set a plan from the Users tab.',
      );
    }
    String nameOf(String uid) {
      for (final user in admin.users) {
        if (user.uid == uid) return user.displayName;
      }
      return uid;
    }

    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: subscriptions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          final isActive = subscription.status == 'active';
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameOf(subscription.userId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                      Text(subscription.plan.label, style: context.textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(
                  label: isActive ? 'Active' : 'Cancelled',
                  color: isActive ? context.palette.success : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
