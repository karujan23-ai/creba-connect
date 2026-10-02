import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/hiring_post_provider.dart';
import '../../utils/navigation.dart';
import '../../widgets/dialogs.dart';
import '../promotion/promote_screen.dart';
import 'hiring_post_form_screen.dart';

/// The "more" menu a brand sees on its own hiring post:
/// Edit, Close / Reopen, Promote and Delete.
class PostOwnerMenu extends StatelessWidget {
  const PostOwnerMenu({super.key, required this.post, this.icon, this.onDeleted});

  final HiringPost post;
  final Widget? icon;

  /// Called after the post has been deleted, e.g. to close its detail screen.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'More',
        icon: icon,
        onSelected: (value) => _onSelected(context, value),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'toggle',
            child: Text(post.isOpen ? 'Close applications' : 'Reopen'),
          ),
          const PopupMenuItem(value: 'promote', child: Text('Promote')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      );

  Future<void> _onSelected(BuildContext context, String value) async {
    final provider = context.read<HiringPostProvider>();
    switch (value) {
      case 'edit':
        pushScreen(context, HiringPostFormScreen(post: post));
      case 'toggle':
        final error = await provider.setStatus(
          post.id,
          post.isOpen ? PostStatus.closed : PostStatus.open,
        );
        if (context.mounted) {
          showResult(
            context,
            error,
            success: post.isOpen ? 'Applications closed.' : 'Reopened.',
          );
        }
      case 'promote':
        pushScreen(
          context,
          PromoteScreen(
            targetId: post.id,
            targetType: TargetType.hiringPost,
            targetLabel: post.title,
          ),
        );
      case 'delete':
        final confirmed = await ConfirmationDialog.show(
          context,
          title: 'Delete this opportunity?',
          message: '"${post.title}" will be removed for good. '
              'Creators who applied will no longer be able to open it.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (!confirmed) return;
        final error = await provider.deletePost(post.id);
        if (!context.mounted) return;
        if (showResult(context, error, success: 'Opportunity deleted.')) {
          onDeleted?.call();
        }
    }
  }
}
