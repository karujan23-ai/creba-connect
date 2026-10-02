import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../models/job_application.dart';
import '../../providers/application_provider.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/application_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../chat/chat_screen.dart';
import '../shared/creator_profile_screen.dart';

/// Applications a brand has received, grouped by stage. With [post] it shows
/// one opportunity's applicants; without, everything the brand received.
///
/// Moving an applicant to a new stage UPDATEs the application document and
/// notifies the creator.
class ApplicantsScreen extends StatelessWidget {
  const ApplicantsScreen({super.key, this.post});

  final HiringPost? post;

  static const _stages = [
    (ApplicationStatus.applied, 'New'),
    (ApplicationStatus.shortlisted, 'Shortlisted'),
    (ApplicationStatus.discussion, 'In Discussion'),
    (ApplicationStatus.selected, 'Selected'),
    (ApplicationStatus.rejected, 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final all = post == null ? provider.applications : provider.forJob(post!.id);
    List<JobApplication> inStage(ApplicationStatus status) =>
        all.where((application) => application.status == status).toList();

    return DefaultTabController(
      length: _stages.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(post == null ? 'Applications' : 'Applicants'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final (status, label) in _stages)
                Tab(text: '$label (${inStage(status).length})'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const LoadingState()
            : provider.error != null
                ? ErrorState(message: provider.error!)
                : TabBarView(
                    children: [
                      for (final (status, _) in _stages)
                        _ApplicantList(applications: inStage(status)),
                    ],
                  ),
      ),
    );
  }
}

class _ApplicantList extends StatelessWidget {
  const _ApplicantList({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No one here yet',
        message: 'Applicants appear in this list as they reach this stage.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: applications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final application = applications[index];
          return ApplicationCard(
            key: ValueKey(application.id),
            application: application,
            forBrand: true,
            onTap: () => pushScreen(
              context,
              CreatorProfileScreen(creatorId: application.creatorId),
            ),
            footer: Row(
              children: [
                AppButton(
                  label: 'Message',
                  variant: AppButtonVariant.secondary,
                  compact: true,
                  expand: false,
                  onPressed: () => pushScreen(
                    context,
                    ChatScreen(
                      otherId: application.creatorId,
                      otherName: application.creatorName,
                    ),
                  ),
                ),
                const Spacer(),
                _StageMenu(application: application),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lets the brand move an applicant to another stage.
class _StageMenu extends StatelessWidget {
  const _StageMenu({required this.application});

  final JobApplication application;

  static const _choices = [
    (ApplicationStatus.shortlisted, 'Shortlist'),
    (ApplicationStatus.discussion, 'Move to discussion'),
    (ApplicationStatus.selected, 'Select'),
    (ApplicationStatus.rejected, 'Reject'),
  ];

  @override
  Widget build(BuildContext context) => PopupMenuButton<ApplicationStatus>(
        tooltip: 'Change stage',
        onSelected: (status) async {
          final error = await context
              .read<ApplicationProvider>()
              .updateStatus(application, status);
          if (context.mounted) {
            showResult(context, error, success: 'Moved to ${status.label}.');
          }
        },
        itemBuilder: (_) => [
          for (final (status, label) in _choices)
            if (status != application.status)
              PopupMenuItem(value: status, child: Text(label)),
        ],
        child: const IgnorePointer(
          child: AppButton(
            label: 'Move to…',
            compact: true,
            expand: false,
            onPressed: _noop,
          ),
        ),
      );

  static void _noop() {}
}
