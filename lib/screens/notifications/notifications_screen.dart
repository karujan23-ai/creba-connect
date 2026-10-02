import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';

/// In-app notifications, live from Firestore. Swipe one away to delete it.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () async {
                final error = await provider.markAllRead();
                if (context.mounted && error != null) showSnack(context, error);
              },
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const LoadingState()
          : provider.error != null
              ? ErrorState(message: provider.error!)
              : notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'You are all caught up',
                      message: 'Updates about applications and your account '
                          'will appear here.',
                    )
                  : ContentWidth(
                      child: ListView.separated(
                        padding: pagePadding(context, top: 4).copyWith(left: 0, right: 0),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                          child: Divider(color: context.palette.border),
                        ),
                        itemBuilder: (_, index) => _NotificationRow(
                          key: ValueKey(notifications[index].id),
                          notification: notifications[index],
                        ),
                      ),
                    ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.read<NotificationProvider>();
    final isUnread = !notification.read;

    return Dismissible(
      key: ValueKey('dismiss-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: palette.danger.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: palette.danger),
      ),
      onDismissed: (_) => provider.delete(notification.id),
      child: InkWell(
        onTap: isUnread ? () => provider.markRead(notification.id) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 12),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isUnread ? palette.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: palette.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Dates.ago(notification.createdAt),
                      style: context.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
