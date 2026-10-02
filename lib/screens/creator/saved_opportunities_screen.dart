import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../theme/app_palette.dart';
import '../../widgets/app_button.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import 'opportunity_tile.dart';

/// Opportunities the creator saved for later.
class SavedOpportunitiesScreen extends StatelessWidget {
  const SavedOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<FavoritesProvider>().savedIds(TargetType.hiringPost);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved opportunities')),
      body: ids.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'Nothing saved yet',
              message: 'Tap the bookmark on an opportunity to keep it here.',
            )
          : ContentWidth(
              child: ListView.separated(
                padding: pagePadding(context, top: 12),
                itemCount: ids.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _SavedPost(key: ValueKey(ids[index]), postId: ids[index]),
              ),
            ),
    );
  }
}

/// Loads one saved post. If the brand has deleted it since, offers to
/// remove the leftover bookmark.
class _SavedPost extends StatefulWidget {
  const _SavedPost({super.key, required this.postId});

  final String postId;

  @override
  State<_SavedPost> createState() => _SavedPostState();
}

class _SavedPostState extends State<_SavedPost> {
  late final Future<HiringPost?> _post =
      context.read<HiringPostProvider>().getById(widget.postId);

  @override
  Widget build(BuildContext context) => FutureBuilder<HiringPost?>(
        future: _post,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 120, child: LoadingState());
          }
          final post = snapshot.data;
          if (post != null) return OpportunityTile(post: post);

          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'This opportunity was removed by the brand.',
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.palette.textMuted),
                  ),
                ),
                AppButton(
                  label: 'Remove',
                  variant: AppButtonVariant.ghost,
                  compact: true,
                  expand: false,
                  onPressed: () =>
                      context.read<FavoritesProvider>().removeRecord(widget.postId),
                ),
              ],
            ),
          );
        },
      );
}
