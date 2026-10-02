import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../chat/conversations_screen.dart';
import '../shared/creator_profile_screen.dart';
import 'creator_home_screen.dart';
import 'my_applications_screen.dart';
import 'opportunity_feed_screen.dart';

/// The creator's main screen: five tabs with a bottom navigation bar.
/// `IndexedStack` keeps every tab alive, so switching tabs never loses
/// scroll position or typed text.
class CreatorShell extends StatefulWidget {
  const CreatorShell({super.key});

  @override
  State<CreatorShell> createState() => _CreatorShellState();
}

class _CreatorShellState extends State<CreatorShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final unread = context.select<ChatProvider, int>((chat) => chat.totalUnread);
    final uid = context.select<UserProvider, String>((p) => p.user?.uid ?? '');

    return PopScope(
      // Back from another tab returns to Home before leaving the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            CreatorHomeScreen(onOpenTab: _goTo),
            const OpportunityFeedScreen(),
            const MyApplicationsScreen(),
            const ConversationsScreen(),
            CreatorProfileScreen(creatorId: uid, isTab: true),
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
              label: 'Applications',
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment,
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
