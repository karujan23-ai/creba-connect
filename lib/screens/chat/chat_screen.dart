import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/state_views.dart';

/// A one-to-one chat. Messages arrive in real time through a Firestore
/// stream held by `ChatProvider`; this screen only displays them.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherId, required this.otherName});

  final String otherId;
  final String otherName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  late final ChatProvider _chat = context.read<ChatProvider>();

  @override
  void initState() {
    super.initState();
    _chat.openChat(otherId: widget.otherId, otherName: widget.otherName);
  }

  @override
  void dispose() {
    _chat.closeChat();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final error = await _chat.send(text);
    if (!mounted || error == null) return;
    // Put the text back so a failed message is not lost.
    _input.text = text;
    showSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messages;
    final myUid = chat.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(name: widget.otherName, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Expanded(
              child: chat.isLoadingMessages
                  ? const LoadingState()
                  : messages.isEmpty
                      ? EmptyState(
                          icon: Icons.waving_hand_outlined,
                          title: 'Say hello',
                          message: 'This is the start of your conversation '
                              'with ${widget.otherName}.',
                        )
                      : ListView.builder(
                          // Newest at the bottom, and the list stays pinned
                          // there as new messages arrive.
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final position = messages.length - 1 - index;
                            final message = messages[position];
                            final previous = position > 0 ? messages[position - 1] : null;
                            final startsNewDay = previous == null ||
                                !DateUtils.isSameDay(previous.createdAt, message.createdAt);
                            return Column(
                              children: [
                                if (startsNewDay) _DayLabel(date: message.createdAt),
                                _Bubble(
                                  message: message,
                                  isMine: message.senderId == myUid,
                                ),
                              ],
                            );
                          },
                        ),
            ),
            _Composer(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(Dates.dayLabel(date), style: context.textTheme.bodySmall),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const corner = Radius.circular(18);
    const tight = Radius.circular(5);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columnWidth = screenWidth > 640 ? 640.0 : screenWidth;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: columnWidth * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
        decoration: BoxDecoration(
          color: isMine ? palette.primary : palette.surface,
          border: isMine ? null : Border.all(color: palette.border),
          borderRadius: BorderRadius.only(
            topLeft: corner,
            topRight: corner,
            bottomLeft: isMine ? corner : tight,
            bottomRight: isMine ? tight : corner,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                message.text,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: isMine ? palette.onPrimary : palette.text,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Dates.time(message.createdAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: (isMine ? palette.onPrimary : palette.textMuted)
                        .withValues(alpha: isMine ? 0.65 : 1),
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    semanticLabel: message.read ? 'Read' : 'Sent',
                    color: palette.onPrimary.withValues(alpha: message.read ? 1 : 0.55),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        10,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              style: context.textTheme.bodyLarge,
              cursorColor: palette.text,
              decoration: const InputDecoration(
                hintText: 'Message',
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: onSend,
            style: IconButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              minimumSize: const Size(46, 46),
            ),
            icon: const Icon(Icons.arrow_upward, size: 20),
          ),
        ],
      ),
    );
  }
}
