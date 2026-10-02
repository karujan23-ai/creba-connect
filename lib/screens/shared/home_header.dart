import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../notifications/notifications_screen.dart';

/// The greeting at the top of both home screens, with the notification bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unread =
        context.select<NotificationProvider, int>((n) => n.unreadCount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingForNow(),
                style: context.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
          child: Material(
            color: palette.surface,
            shape: CircleBorder(side: BorderSide(color: palette.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => pushScreen(context, const NotificationsScreen()),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none, color: palette.text, size: 22),
                    if (unread > 0)
                      Positioned(
                        top: 12,
                        right: 13,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A horizontally scrolling row of fixed-height cards.
class HorizontalCards extends StatelessWidget {
  const HorizontalCards({super.key, required this.children, this.height = 176});

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          // Lets the row bleed to the screen edges while lining up with
          // the page padding.
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          clipBehavior: Clip.none,
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) => children[index],
        ),
      );
}
