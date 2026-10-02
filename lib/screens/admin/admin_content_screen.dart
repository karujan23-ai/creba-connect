import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/report.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/availability_card.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hiring_post_card.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../shared/job_detail_screen.dart';

/// Admin: all hiring posts, all creator availability posts, and reports.
class AdminContentScreen extends StatelessWidget {
  const AdminContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Content'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Hiring posts (${admin.hiringPosts.length})'),
              Tab(text: 'Creator posts (${admin.availabilityPosts.length})'),
              Tab(text: 'Reports (${admin.openReports.length})'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_HiringPosts(), _AvailabilityPosts(), _Reports()],
        ),
      ),
    );
  }
}

/// Asks before an admin removes someone else's content.
Future<bool> _confirmRemoval(BuildContext context, String title) =>
    ConfirmationDialog.show(
      context,
      title: 'Remove this post?',
      message: '"$title" will be deleted for everyone. This is recorded in the admin log.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

class _HiringPosts extends StatelessWidget {
  const _HiringPosts();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final posts = admin.hiringPosts;
    if (posts.isEmpty) {
      return const EmptyState(icon: Icons.work_outline, title: 'No hiring posts');
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return HiringPostCard(
            key: ValueKey(post.id),
            post: post,
            onTap: () => pushScreen(context, JobDetailScreen(post: post)),
            footer: Row(
              children: [
                Expanded(
                  child: Text(
                    '${post.viewCount} views · ${post.applicationCount} applications',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                AppButton(
                  label: 'Remove',
                  variant: AppButtonVariant.danger,
                  compact: true,
                  expand: false,
                  onPressed: () async {
                    if (!await _confirmRemoval(context, post.title)) return;
                    final error = await admin.deleteHiringPost(post);
                    if (context.mounted) showResult(context, error, success: 'Post removed.');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvailabilityPosts extends StatelessWidget {
  const _AvailabilityPosts();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final posts = admin.availabilityPosts;
    if (posts.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'No creator posts',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return AvailabilityCard(
            key: ValueKey(post.id),
            post: post,
            footer: Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Remove',
                variant: AppButtonVariant.danger,
                compact: true,
                expand: false,
                onPressed: () async {
                  if (!await _confirmRemoval(context, post.title)) return;
                  final error = await admin.deleteAvailabilityPost(post);
                  if (context.mounted) showResult(context, error, success: 'Post removed.');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports();

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AdminProvider>().reports;
    if (reports.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        title: 'No reports',
        message: 'Reports sent by users will appear here.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            _ReportCard(key: ValueKey(reports[index].id), report: reports[index]),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({super.key, required this.report});

  final Report report;

  Future<void> _setStatus(BuildContext context, ReportStatus status) async {
    final error =
        await context.read<AdminProvider>().setReportStatus(report, status);
    if (context.mounted) {
      showResult(context, error, success: 'Report ${status.label.toLowerCase()}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOpen = report.status == ReportStatus.open;
    final statusColor = switch (report.status) {
      ReportStatus.open => palette.warning,
      ReportStatus.resolved => palette.success,
      ReportStatus.dismissed => palette.textMuted,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.targetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: report.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${report.targetType.label} · ${Dates.ago(report.createdAt)}',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(report.reason, style: context.textTheme.titleSmall),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              report.description,
              style: context.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 12),
            Divider(color: palette.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Dismiss',
                    variant: AppButtonVariant.secondary,
                    compact: true,
                    onPressed: () => _setStatus(context, ReportStatus.dismissed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Resolve',
                    compact: true,
                    onPressed: () => _setStatus(context, ReportStatus.resolved),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
