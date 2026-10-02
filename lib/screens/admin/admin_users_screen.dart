import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/state_views.dart';
import '../shared/brand_profile_screen.dart';
import '../shared/creator_profile_screen.dart';

/// Admin: every creator and brand account, with suspend and plan controls.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final creators = admin.usersWithRole(UserRole.creator);
    final brands = admin.usersWithRole(UserRole.brand);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Creators (${creators.length})'),
              Tab(text: 'Brands (${brands.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_UserList(users: creators), _UserList(users: brands)],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users});

  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const EmptyState(icon: Icons.people_outline, title: 'No users yet');
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) =>
            _UserCard(key: ValueKey(users[index].uid), user: users[index]),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final palette = context.palette;
    final plan = admin.planOf(user.uid);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      onTap: user.onboardingComplete
          ? () => pushScreen(
                context,
                user.isCreator
                    ? CreatorProfileScreen(creatorId: user.uid)
                    : BrandProfileScreen(brandId: user.uid),
              )
          : null,
      child: Row(
        children: [
          ProfileAvatar(name: user.displayName, size: 42, square: user.isBrand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall,
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (!user.isActive) StatusBadge(label: 'Suspended', color: palette.danger),
                    if (!user.onboardingComplete) const StatusBadge(label: 'Onboarding'),
                    if (plan != SubscriptionPlan.free)
                      StatusBadge(label: plan.label, color: palette.accent),
                    StatusBadge(label: 'Joined ${Dates.short(user.createdAt)}'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Manage',
            icon: Icon(Icons.more_vert, color: palette.textMuted),
            onSelected: (value) => _onSelected(context, value, plan),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'active',
                child: Text(user.isActive ? 'Suspend account' : 'Reactivate account'),
              ),
              PopupMenuItem(
                value: 'plan',
                child: Text(
                  plan == SubscriptionPlan.free ? 'Set Pro plan' : 'Set Free plan',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    String value,
    SubscriptionPlan currentPlan,
  ) async {
    final admin = context.read<AdminProvider>();
    if (value == 'active') {
      if (user.isActive) {
        final confirmed = await ConfirmationDialog.show(
          context,
          title: 'Suspend ${user.displayName}?',
          message: 'They will be signed out of the app until you reactivate them.',
          confirmLabel: 'Suspend',
          isDestructive: true,
        );
        if (!confirmed) return;
      }
      final error = await admin.setUserActive(user, isActive: !user.isActive);
      if (context.mounted) {
        showResult(
          context,
          error,
          success: user.isActive ? 'Account suspended.' : 'Account reactivated.',
        );
      }
    } else {
      final proPlan =
          user.isCreator ? SubscriptionPlan.creatorPro : SubscriptionPlan.brandPro;
      final newPlan = currentPlan == SubscriptionPlan.free ? proPlan : SubscriptionPlan.free;
      final error = await admin.setPlan(user, newPlan);
      if (context.mounted) {
        showResult(context, error, success: 'Plan set to ${newPlan.label}.');
      }
    }
  }
}
