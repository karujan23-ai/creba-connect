import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/application_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hiring_post_card.dart';
import '../../widgets/price_display.dart';
import '../../widgets/report_sheet.dart';
import '../shared/job_detail_screen.dart';
import 'apply_sheet.dart';

/// A hiring post as a creator sees it in a feed, with the creator's actions:
/// Apply, Save, Share, Not interested and Report.
class OpportunityTile extends StatelessWidget {
  const OpportunityTile({super.key, required this.post, this.showMatch = true});

  final HiringPost post;
  final bool showMatch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final myProfile = context.watch<CreatorProvider>().myProfile;
    final application = context.watch<ApplicationProvider>().mineForJob(post.id);
    final isSaved = context.watch<FavoritesProvider>().isSaved(post.id);
    final hasApplied =
        application != null && application.status != ApplicationStatus.withdrawn;

    return HiringPostCard(
      post: post,
      onTap: () => pushScreen(context, JobDetailScreen(post: post)),
      matchPercent: showMatch && myProfile != null
          ? MatchScorer.creatorForPost(myProfile, post)
          : null,
      headerTrailing: PopupMenuButton<String>(
        tooltip: 'More',
        icon: Icon(Icons.more_horiz, color: palette.textMuted),
        onSelected: (value) => _onMenu(context, value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'share', child: Text('Share')),
          PopupMenuItem(value: 'hide', child: Text('Not interested')),
          PopupMenuItem(value: 'report', child: Text('Report')),
        ],
      ),
      footer: Row(
        children: [
          if (hasApplied)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ApplicationStatusBadge(status: application.status),
              ),
            )
          else
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: post.deadlinePassed ? 'Closed' : 'Apply now',
                  compact: true,
                  expand: false,
                  onPressed: post.deadlinePassed
                      ? null
                      : () => ApplySheet.show(context, post),
                ),
              ),
            ),
          IconButton(
            tooltip: isSaved ? 'Remove from saved' : 'Save',
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? palette.text : palette.textMuted,
            ),
            onPressed: () async {
              final error = await context
                  .read<FavoritesProvider>()
                  .toggle(post.id, TargetType.hiringPost);
              if (context.mounted && error != null) showSnack(context, error);
            },
          ),
        ],
      ),
    );
  }

  void _onMenu(BuildContext context, String value) {
    switch (value) {
      case 'share':
        shareOpportunity(context, post);
      case 'hide':
        final posts = context.read<HiringPostProvider>()..hide(post.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Hidden from your feed.'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => posts.unhide(post.id),
              ),
            ),
          );
      case 'report':
        ReportSheet.show(
          context,
          targetId: post.id,
          targetType: TargetType.hiringPost,
          targetLabel: post.title,
        );
    }
  }
}

/// "Share" copies a short text summary of the opportunity so it can be
/// pasted into any messaging app.
Future<void> shareOpportunity(BuildContext context, HiringPost post) async {
  final currency = context.read<SettingsProvider>().currency;
  final summary = [
    '${post.title} — ${post.brandName}',
    if (post.locationLabel.isNotEmpty) post.locationLabel,
    if (post.startDate != null) Dates.full(post.startDate!),
    budgetText(post, currency),
    'Found on CreBa Connect',
  ].join('\n');
  await Clipboard.setData(ClipboardData(text: summary));
  if (context.mounted) showSnack(context, 'Details copied. Paste to share.');
}
