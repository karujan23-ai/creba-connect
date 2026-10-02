import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/availability_post.dart';
import '../../providers/availability_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/availability_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import 'availability_form_screen.dart';

/// The creator's own availability posts. This screen shows the whole CRUD
/// cycle in one place: create, read (live list), edit, pause and delete.
class MyAvailabilityScreen extends StatelessWidget {
  const MyAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvailabilityProvider>();
    final posts = provider.myPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability posts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              label: 'New',
              icon: Icons.add,
              compact: true,
              expand: false,
              onPressed: () => pushScreen(context, const AvailabilityFormScreen()),
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
                      icon: Icons.event_available_outlined,
                      title: 'No availability posts',
                      message: 'Tell brands when you are free and what kind '
                          'of work you want.',
                      actionLabel: 'Create a post',
                      onAction: () =>
                          pushScreen(context, const AvailabilityFormScreen()),
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

  final AvailabilityPost post;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AvailabilityProvider>();

    return AvailabilityCard(
      post: post,
      showCreator: false,
      footer: Row(
        children: [
          Text(
            post.isActive ? 'Visible to brands' : 'Hidden',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Switch(
            value: post.isActive,
            onChanged: (value) async {
              final error = await provider.setActive(post.id, isActive: value);
              if (context.mounted && error != null) showSnack(context, error);
            },
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => pushScreen(context, AvailabilityFormScreen(post: post)),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline, size: 20, color: context.palette.danger),
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Delete this post?',
                message: '"${post.title}" will be removed for good.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (!confirmed) return;
              final error = await provider.deletePost(post.id);
              if (context.mounted) showResult(context, error, success: 'Post deleted.');
            },
          ),
        ],
      ),
    );
  }
}
