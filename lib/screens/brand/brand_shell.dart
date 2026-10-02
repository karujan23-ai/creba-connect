import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../chat/conversations_screen.dart';
import '../shared/brand_profile_screen.dart';
import 'brand_home_screen.dart';
import 'discover_creators_screen.dart';
import 'my_posts_screen.dart';

/// The brand's main screen: five tabs with a bottom navigation bar.
class BrandShell extends StatefulWidget {
  const BrandShell({super.key});

  @override
  State<BrandShell> createState() => _BrandShellState();
}

class _BrandShellState extends State<BrandShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final unread = context.select<ChatProvider, int>((chat) => chat.totalUnread);
    final uid = context.select<UserProvider, String>((p) => p.user?.uid ?? '');

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
            BrandHomeScreen(onOpenTab: _goTo),
            const DiscoverCreatorsScreen(),
            const MyPostsScreen(),
            const ConversationsScreen(),
            BrandProfileScreen(brandId: uid, isTab: true),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          onTap: _goTo,
          items: [
            const NavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
            ),
            const NavItem(
              label: 'Discover',
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore,
            ),
            const NavItem(
              label: 'Opportunities',
              icon: Icons.work_outline,
              selectedIcon: Icons.work,
            ),
            NavItem(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              badgeCount: unread,
            ),
            const NavItem(
              label: 'Profile',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        ),
      ),
    );
  }
}
