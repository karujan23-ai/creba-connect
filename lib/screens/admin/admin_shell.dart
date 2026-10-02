import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dialogs.dart';
import '../settings/settings_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_content_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_users_screen.dart';

/// The admin area. Only reachable when `users/{uid}.role` is "admin", which
/// can only be set by hand in the Firebase Console. The security rules check
/// the same thing on the server for every admin read and write.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            AdminDashboardScreen(onOpenTab: _goTo),
            const AdminUsersScreen(),
            const AdminContentScreen(),
            const AdminPaymentsScreen(),
            const SettingsScreen(extraSections: [_AdminTools()]),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          onTap: _goTo,
          items: [
            const NavItem(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            const NavItem(
              label: 'Users',
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
            ),
            NavItem(
              label: 'Content',
              icon: Icons.article_outlined,
              selectedIcon: Icons.article,
              badgeCount: admin.openReports.length,
            ),
            NavItem(
              label: 'Payments',
              icon: Icons.payments_outlined,
              selectedIcon: Icons.payments,
              badgeCount: admin.promotionRequests.length,
            ),
            const NavItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin-only entries added to the Settings screen.
class _AdminTools extends StatelessWidget {
  const _AdminTools();

  @override
  Widget build(BuildContext context) => SettingsGroup(
        title: 'Admin tools',
        children: [
          SettingsRow(
            label: 'Categories',
            onTap: () => pushScreen(context, const AdminCategoriesScreen()),
          ),
          SettingsRow(
            label: 'Sample data',
            onTap: () => showAppSheet<void>(context, builder: (_) => const _SampleDataSheet()),
          ),
        ],
      );
}

class _SampleDataSheet extends StatefulWidget {
  const _SampleDataSheet();

  @override
  State<_SampleDataSheet> createState() => _SampleDataSheetState();
}

class _SampleDataSheetState extends State<_SampleDataSheet> {
  bool _isWorking = false;

  Future<void> _run(Future<String> Function(AdminProvider admin) action) async {
    setState(() => _isWorking = true);
    final message = await action(context.read<AdminProvider>());
    if (!mounted) return;
    setState(() => _isWorking = false);
    showSnack(context, message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
        title: 'Sample data',
        subtitle: 'Adds invented brands, creators and posts so the app is not '
            'empty during a demo. Everything is labelled "Sample" and can be '
            'removed again.',
        child: Column(
          children: [
            AppButton(
              label: 'Add sample data',
              isLoading: _isWorking,
              onPressed: () => _run(
                (admin) async => await admin.addDemoData() ?? 'Sample data added.',
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Remove sample data',
              variant: AppButtonVariant.danger,
              onPressed: _isWorking ? null : () => _run((admin) => admin.removeDemoData()),
            ),
          ],
        ),
      );
}
