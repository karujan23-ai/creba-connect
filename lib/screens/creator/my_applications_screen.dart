import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/job_application.dart';
import '../../providers/application_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/application_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../chat/chat_screen.dart';
import '../shared/job_detail_screen.dart';

/// The creator's "Applications" tab: everything they applied to, grouped by
/// stage. Updates live when a brand changes a status.
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  static const _stages = [
    ApplicationStatus.applied,
    ApplicationStatus.shortlisted,
    ApplicationStatus.discussion,
    ApplicationStatus.selected,
    ApplicationStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();

    return DefaultTabController(
      length: _stages.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My applications'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'All (${provider.applications.length})'),
              for (final stage in _stages)
                Tab(text: '${stage.label} (${provider.countWithStatus(stage)})'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const LoadingState()
            : provider.error != null
                ? ErrorState(message: provider.error!)
                : TabBarView(
                    children: [
                      _ApplicationList(applications: provider.applications),
                      for (final stage in _stages)
                        _ApplicationList(applications: provider.withStatus(stage)),
                    ],
                  ),
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Nothing here yet',
        message: 'Applications you send will show up in this list.',
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
            forBrand: false,
            onTap: () => _openJob(context, application),
            footer: Row(
              children: [
                AppButton(
                  label: 'Message brand',
                  variant: AppButtonVariant.secondary,
                  compact: true,
                  expand: false,
                  onPressed: () => pushScreen(
                    context,
                    ChatScreen(
                      otherId: application.brandId,
                      otherName: application.brandName,
                    ),
                  ),
                ),
                const Spacer(),
                if (application.canWithdraw)
                  AppButton(
                    label: 'Withdraw',
                    variant: AppButtonVariant.ghost,
                    compact: true,
                    expand: false,
                    onPressed: () => _withdraw(context, application),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openJob(BuildContext context, JobApplication application) async {
    final post = await context.read<HiringPostProvider>().getById(application.jobId);
    if (!context.mounted) return;
    if (post == null) {
      showSnack(context, 'This opportunity is no longer available.');
    } else {
      pushScreen(context, JobDetailScreen(post: post));
    }
  }

  Future<void> _withdraw(BuildContext context, JobApplication application) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Withdraw application?',
      message: 'The brand will no longer see you as an applicant for '
          '"${application.jobTitle}". You can apply again later.',
      confirmLabel: 'Withdraw',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<ApplicationProvider>().withdraw(application);
    if (context.mounted) showResult(context, error, success: 'Application withdrawn.');
  }
}
