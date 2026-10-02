import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/layout.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/state_views.dart';
import 'chat_screen.dart';

/// The "Messages" tab: every conversation, most recent first, updating live.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final myUid = chat.uid ?? '';
    final conversations = chat.conversations;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chat.isLoading
          ? const LoadingState()
          : chat.error != null
              ? ErrorState(message: chat.error!)
              : conversations.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages yet',
                      message: 'Start a conversation from a profile or an '
                          'application.',
                    )
                  : ContentWidth(
                      child: ListView.separated(
                        padding: pagePadding(context, top: 4).copyWith(left: 0, right: 0),
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => Padding(
                          padding: const EdgeInsets.only(left: 82, right: AppSpacing.page),
                          child: Divider(color: context.palette.border),
                        ),
                        itemBuilder: (_, index) => _ConversationRow(
                          key: ValueKey(conversations[index].id),
                          conversation: conversations[index],
                          myUid: myUid,
                        ),
                      ),
                    ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({super.key, required this.conversation, required this.myUid});

  final Conversation conversation;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = conversation.otherParticipantName(myUid);
    final unread = conversation.unreadFor(myUid);
    final sentByMe = conversation.lastSenderId == myUid;

    return InkWell(
      onTap: () => pushScreen(
        context,
        ChatScreen(otherId: conversation.otherParticipantId(myUid), otherName: name),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 14),
        child: Row(
          children: [
            ProfileAvatar(name: name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Dates.ago(conversation.updatedAt),
                        style: context.textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sentByMe ? 'You: ' : ''}${conversation.lastMessage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: unread > 0 ? palette.text : palette.textMuted,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
