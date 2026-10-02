import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../widgets/badges.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';

/// Shows the Free and Pro plans and which one the user is on.
///
/// The plan is stored in Firestore (`subscriptions/{uid}`) and can only be
/// changed by an admin. Billing is NOT implemented: there is no way to pay
/// from this screen, and it says so.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCreator = context.watch<UserProvider>().user?.isCreator ?? true;
    final currentPlan = context.watch<PromotionProvider>().plan;
    final settings = context.watch<SettingsProvider>();
    final proPlan = isCreator ? SubscriptionPlan.creatorPro : SubscriptionPlan.brandPro;

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 8),
          children: [
            _PlanCard(
              name: SubscriptionPlan.free.label,
              price: 'Free',
              isCurrent: currentPlan == SubscriptionPlan.free,
              features: const ['Basic profile', 'Limited posts', 'Normal discovery'],
            ),
            const SizedBox(height: 12),
            _PlanCard(
              name: proPlan.label,
              price: '${settings.money(proPlan.monthlyPriceNpr)} / month',
              isCurrent: currentPlan == proPlan,
              features: const [
                'Profile boost',
                'Advanced filters',
                'Analytics',
                'More active opportunities',
                'Priority visibility',
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Paid plans are not available to buy yet because online payment '
              'is not connected. The plan shown here is set by the CreBa '
              'Connect team.',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.isCurrent,
    required this.features,
  });

  final String name;
  final String price;
  final bool isCurrent;
  final List<String> features;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(name, style: context.textTheme.headlineSmall)),
                if (isCurrent)
                  StatusBadge(label: 'Your plan', color: context.palette.success),
              ],
            ),
            const SizedBox(height: 4),
            Text(price, style: context.textTheme.titleMedium),
            const SizedBox(height: 14),
            BulletList(items: features),
          ],
        ),
      );
}
