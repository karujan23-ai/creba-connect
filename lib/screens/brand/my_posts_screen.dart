import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hiring_post.dart';
import '../../providers/hiring_post_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/hiring_post_card.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../shared/job_detail_screen.dart';
import 'applicants_screen.dart';
import 'hiring_post_form_screen.dart';
import 'post_owner_menu.dart';

/// The brand's "Opportunities" tab: its own hiring posts.
///
/// This one screen demonstrates the full CRUD cycle on a UID-owned
/// collection: create (Hire a creator), read (this live list), update
/// (Edit, Close) and delete.
class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HiringPostProvider>();
    final posts = provider.myPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your opportunities'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              label: 'New',
              icon: Icons.add,
              compact: true,
              expand: false,
              onPressed: () => pushScreen(context, const HiringPostFormScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingState()
          : provider.error != null
              ? ErrorState(message: provider.error!)
              : posts.isEmpty
                  ? EmptyState(
                      icon: Icons.work_outline,
                      title: 'No opportunities yet',
                      message: 'Post your first opportunity and creators '
                          'can start applying.',
                      actionLabel: 'Hire a creator',
                      onAction: () =>
                          pushScreen(context, const HiringPostFormScreen()),
                    )
                  : ContentWidth(
                      child: ListView.separated(
                        padding: pagePadding(context, top: 12),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _MyPostCard(
                          key: ValueKey(posts[index].id),
                          post: posts[index],
                        ),
                      ),
                    ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({super.key, required this.post});

  final HiringPost post;

  @override
  Widget build(BuildContext context) => HiringPostCard(
        post: post,
        onTap: () => pushScreen(context, JobDetailScreen(post: post)),
        headerTrailing: PostOwnerMenu(
          post: post,
          icon: Icon(Icons.more_horiz, color: context.palette.textMuted),
        ),
        footer: Row(
          children: [
            Expanded(
              child: Text(
                '${post.viewCount} views · ${post.applicationCount} applications',
                style: context.textTheme.bodySmall,
              ),
            ),
            AppButton(
              label: 'Applicants',
              variant: AppButtonVariant.secondary,
              compact: true,
              expand: false,
              onPressed: () => pushScreen(context, ApplicantsScreen(post: post)),
            ),
          ],
        ),
      );
}
