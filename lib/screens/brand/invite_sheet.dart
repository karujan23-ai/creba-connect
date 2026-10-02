import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../models/hiring_post.dart';
import '../../providers/chat_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/price_display.dart';
import 'hiring_post_form_screen.dart';

/// "Hire / Invite": the brand picks one of its open opportunities and the
/// creator receives an invitation as a chat message.
class InviteSheet extends StatelessWidget {
  const InviteSheet({super.key, required this.creator});

  final CreatorProfile creator;

  static Future<void> show(BuildContext context, CreatorProfile creator) =>
      showAppSheet<void>(context, builder: (_) => InviteSheet(creator: creator));

  Future<void> _invite(BuildContext context, HiringPost post) async {
    final firstName = creator.fullName.split(' ').first;
    final error = await context.read<ChatProvider>().sendDirect(
          otherId: creator.uid,
          otherName: creator.fullName,
          text: 'Hi $firstName, we think you would be a great fit for our '
              'opportunity "${post.title}". You can find it under Discover '
              'and apply there. Happy to answer any questions here.',
        );
    if (!context.mounted) return;
    if (showResult(context, error, success: 'Invitation sent to ${creator.fullName}.')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<HiringPostProvider>().myOpenPosts;

    return SheetScaffold(
      title: 'Invite ${creator.fullName.split(' ').first}',
      subtitle: 'Choose the opportunity to invite them to.',
      child: posts.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have no open opportunities yet. Create one first, then '
                  'invite creators to it.',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: context.palette.textMuted),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Hire a creator',
                  onPressed: () {
                    Navigator.of(context).pop();
                    pushScreen(context, const HiringPostFormScreen());
                  },
                ),
              ],
            )
          : Column(
              children: [
                for (final post in posts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => _invite(context, post),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                BudgetDisplay(
                                  post: post,
                                  style: context.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          MatchBadge(
                            percent: MatchScorer.creatorForPost(creator, post),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
