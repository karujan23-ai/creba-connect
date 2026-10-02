import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../models/enums.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/creator_card.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../shared/creator_profile_screen.dart';
import 'discover_creators_screen.dart';

/// Creators the brand saved for later.
class SavedCreatorsScreen extends StatelessWidget {
  const SavedCreatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<FavoritesProvider>().savedIds(TargetType.creator);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved creators')),
      body: ids.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved creators',
              message: 'Tap the bookmark on a creator to keep them here.',
            )
          : ContentWidth(
              child: ListView.separated(
                padding: pagePadding(context, top: 12),
                itemCount: ids.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _SavedCreator(key: ValueKey(ids[index]), creatorId: ids[index]),
              ),
            ),
    );
  }
}

class _SavedCreator extends StatefulWidget {
  const _SavedCreator({super.key, required this.creatorId});

  final String creatorId;

  @override
  State<_SavedCreator> createState() => _SavedCreatorState();
}

class _SavedCreatorState extends State<_SavedCreator> {
  late final Future<CreatorProfile?> _creator =
      context.read<CreatorProvider>().getById(widget.creatorId);

  @override
  Widget build(BuildContext context) => FutureBuilder<CreatorProfile?>(
        future: _creator,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 110, child: LoadingState());
          }
          final creator = snapshot.data;
          if (creator != null) {
            return CreatorCard(
              creator: creator,
              trailing: SaveCreatorButton(creator: creator),
              onTap: () => pushScreen(
                context,
                CreatorProfileScreen(creatorId: creator.uid),
              ),
            );
          }
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'This creator profile is no longer available.',
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
                      context.read<FavoritesProvider>().removeRecord(widget.creatorId),
                ),
              ],
            ),
          );
        },
      );
}
