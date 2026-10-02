import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/application_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';
import '../../widgets/price_display.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_sheet.dart';
import '../brand/applicants_screen.dart';
import '../brand/post_owner_menu.dart';
import '../creator/apply_sheet.dart';
import '../creator/opportunity_tile.dart';
import 'brand_profile_screen.dart';

/// The full view of one hiring post. Creators can apply and save; the brand
/// that owns it can edit, close, promote or delete it.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.post});

  final HiringPost post;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HiringPostProvider>().recordView(widget.post);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final user = context.watch<UserProvider>().user;
    // Uses the live copy when there is one, so edits show immediately.
    final post =
        context.watch<HiringPostProvider>().findLoaded(widget.post.id) ?? widget.post;
    final isOwner = user?.uid == post.brandId;
    final isCreator = user?.isCreator ?? false;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        actions: [
          if (isCreator) _SaveButton(postId: post.id),
          if (isOwner)
            PostOwnerMenu(post: post, onDeleted: () => Navigator.of(context).pop())
          else if (user != null && !user.isAdmin)
            _ViewerMenu(post: post),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 4),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              onTap: isOwner
                  ? null
                  : () => pushScreen(context, BrandProfileScreen(brandId: post.brandId)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ProfileAvatar(name: post.brandName, size: 40, square: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrandNameLine(
                            name: post.brandName,
                            isVerified: post.brandVerified,
                            style: context.textTheme.titleMedium,
                          ),
                          Text(
                            'Posted ${Dates.ago(post.createdAt)}',
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (!isOwner) Icon(Icons.chevron_right, color: palette.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(post.title, style: context.textTheme.displaySmall?.copyWith(fontSize: 34)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (post.isPromoted) StatusBadge(label: 'Promoted', color: palette.accent),
                if (!post.isOpen) const StatusBadge(label: 'Closed'),
                if (post.isDemo) const StatusBadge(label: 'Sample'),
                if (isCreator) _MatchLine(post: post),
              ],
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    semanticLabel: 'Image for ${post.title}',
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: palette.surfaceAlt,
                      child: Icon(Icons.image_not_supported_outlined, color: palette.textFaint),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _Facts(post: post),
            const SizedBox(height: 24),
            Text(post.description, style: context.textTheme.bodyLarge),
            if (post.requirements.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Overline('Requirements'),
              const SizedBox(height: 12),
              BulletList(items: post.requirements),
            ],
            if (post.deliverables.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Overline('Deliverables'),
              const SizedBox(height: 12),
              BulletList(items: post.deliverables),
            ],
            if (post.creatorTypes.isNotEmpty || post.niches.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Overline('Looking for'),
              const SizedBox(height: 12),
              ChipWrap(labels: [...post.creatorTypes, ...post.niches]),
            ],
            if (isOwner) ...[
              const SizedBox(height: 28),
              const Overline('Performance'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(value: '${post.viewCount}', label: 'Views'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      value: '${post.applicationCount}',
                      label: 'Applications',
                    ),
                  ),
                ],
              ),
            ],
            // Leaves room for the action bar that floats over the content.
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: isOwner
          ? _ActionBar(
              child: AppButton(
                label: 'View applicants (${post.applicationCount})',
                onPressed: () => pushScreen(context, ApplicantsScreen(post: post)),
              ),
            )
          : isCreator
              ? _ActionBar(child: _ApplyAction(post: post))
              : null,
    );
  }
}

/// The key facts as a quiet two-column list.
class _Facts extends StatelessWidget {
  const _Facts({required this.post});

  final HiringPost post;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, Widget)>[
      (
        Icons.payments_outlined,
        'Budget',
        BudgetDisplay(post: post, style: context.textTheme.titleMedium),
      ),
      if (post.locationLabel.isNotEmpty)
        (Icons.place_outlined, 'Location', _value(context, post.locationLabel)),
      if (post.startDate != null)
        (
          Icons.calendar_today_outlined,
          'Date',
          _value(context, Dates.full(post.startDate!)),
        ),
      if (post.workType.isNotEmpty)
        (
          Icons.schedule_outlined,
          'Work type',
          _value(
            context,
            [post.workType, if (post.duration.isNotEmpty) post.duration].join(' · '),
          ),
        ),
      (
        Icons.people_outline,
        'Creators needed',
        _value(context, '${post.creatorsNeeded}'),
      ),
      if (post.deadline != null)
        (
          Icons.event_busy_outlined,
          'Apply by',
          _value(context, Dates.full(post.deadline!)),
        ),
      (
        Icons.forum_outlined,
        'Contact',
        _value(context, post.contactPreference),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) Divider(color: context.palette.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(rows[index].$1, size: 18, color: context.palette.textMuted),
                  const SizedBox(width: 12),
                  Text(
                    rows[index].$2,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.palette.textMuted),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(alignment: Alignment.centerRight, child: rows[index].$3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _value(BuildContext context, String text) => Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleSmall,
      );
}

class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.post});

  final HiringPost post;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CreatorProvider>().myProfile;
    if (profile == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'Based on your profile: type, niches, city, availability and rate.',
      child: MatchBadge(percent: MatchScorer.creatorForPost(profile, post)),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final isSaved = context.watch<FavoritesProvider>().isSaved(postId);
    return IconButton(
      tooltip: isSaved ? 'Remove from saved' : 'Save',
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () async {
        final error = await context
            .read<FavoritesProvider>()
            .toggle(postId, TargetType.hiringPost);
        if (context.mounted && error != null) showSnack(context, error);
      },
    );
  }
}

/// Share and Report, for viewers who do not own the post.
class _ViewerMenu extends StatelessWidget {
  const _ViewerMenu({required this.post});

  final HiringPost post;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'More',
        onSelected: (value) {
          if (value == 'share') {
            shareOpportunity(context, post);
          } else {
            ReportSheet.show(
              context,
              targetId: post.id,
              targetType: TargetType.hiringPost,
              targetLabel: post.title,
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'share', child: Text('Share')),
          PopupMenuItem(value: 'report', child: Text('Report')),
        ],
      );
}

/// The glass bar pinned to the bottom of the screen.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GlassCard(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 12),
            child: ContentWidth(shrinkHeight: true, child: child),
          ),
        ),
      );
}

class _ApplyAction extends StatelessWidget {
  const _ApplyAction({required this.post});

  final HiringPost post;

  @override
  Widget build(BuildContext context) {
    final application = context.watch<ApplicationProvider>().mineForJob(post.id);
    final hasApplied =
        application != null && application.status != ApplicationStatus.withdrawn;

    if (hasApplied) {
      return Row(
        children: [
          Expanded(
            child: Text('You applied', style: context.textTheme.titleMedium),
          ),
          ApplicationStatusBadge(status: application.status),
        ],
      );
    }
    final isClosed = !post.isOpen || post.deadlinePassed;
    return AppButton(
      label: isClosed
          ? 'Applications closed'
          : (application == null ? 'Apply now' : 'Apply again'),
      onPressed: isClosed ? null : () => ApplySheet.show(context, post),
    );
  }
}
