import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../models/enums.dart';
import '../../models/filters.dart';
import '../../providers/availability_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../utils/validators.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/availability_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/creator_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../shared/creator_profile_screen.dart';

/// The brand's "Discover" tab. Two views of the same goal — finding a
/// creator: browse profiles, or browse creators who posted availability.
class DiscoverCreatorsScreen extends StatelessWidget {
  const DiscoverCreatorsScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Discover creators'),
            bottom: const TabBar(
              tabs: [Tab(text: 'Creators'), Tab(text: 'Available now')],
            ),
          ),
          body: const TabBarView(
            children: [_CreatorsTab(), _AvailabilityTab()],
          ),
        ),
      );
}

class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreatorProvider>();
    final brand = context.watch<BrandProvider>().myBrand;
    final results = provider.filteredCreators;

    return ContentWidth(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 12),
            child: AppSearchBar(
              hint: 'Search name, niche, city…',
              onChanged: provider.setQuery,
              activeFilters: provider.filter.activeCount,
              onFilterTap: () => showAppSheet<void>(
                context,
                builder: (_) => _CreatorFilterSheet(initial: provider.filter),
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingState()
                : provider.error != null
                    ? ErrorState(message: provider.error!)
                    : results.isEmpty
                        ? EmptyState(
                            icon: Icons.person_search_outlined,
                            title: 'No creators found',
                            message: provider.creators.isEmpty
                                ? 'Creators will appear here as they join.'
                                : 'Try a different search or clear your filters.',
                            actionLabel:
                                provider.filter.activeCount > 0 ? 'Clear filters' : null,
                            onAction: provider.clearFilter,
                          )
                        : ListView.separated(
                            padding: pagePadding(context, top: 4),
                            itemCount: results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final creator = results[index];
                              return CreatorCard(
                                key: ValueKey(creator.uid),
                                creator: creator,
                                matchPercent: brand == null
                                    ? null
                                    : MatchScorer.creatorForBrand(creator, brand),
                                trailing: SaveCreatorButton(creator: creator),
                                onTap: () => pushScreen(
                                  context,
                                  CreatorProfileScreen(creatorId: creator.uid),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// The bookmark button on a creator card.
class SaveCreatorButton extends StatelessWidget {
  const SaveCreatorButton({super.key, required this.creator});

  final CreatorProfile creator;

  @override
  Widget build(BuildContext context) {
    final isSaved = context.watch<FavoritesProvider>().isSaved(creator.uid);
    final palette = context.palette;
    return IconButton(
      tooltip: isSaved ? 'Remove from saved' : 'Save creator',
      visualDensity: VisualDensity.compact,
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? palette.text : palette.textMuted,
      ),
      onPressed: () async {
        final error = await context
            .read<FavoritesProvider>()
            .toggle(creator.uid, TargetType.creator);
        if (context.mounted && error != null) showSnack(context, error);
      },
    );
  }
}

class _AvailabilityTab extends StatelessWidget {
  const _AvailabilityTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvailabilityProvider>();
    final posts = provider.activePosts;

    if (provider.isLoading) return const LoadingState();
    if (provider.error != null) return ErrorState(message: provider.error!);
    if (posts.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'No availability posts',
        message: 'When creators announce they are free for work, '
            'their posts appear here.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => AvailabilityCard(
          key: ValueKey(posts[index].id),
          post: posts[index],
          onTap: () => pushScreen(
            context,
            CreatorProfileScreen(creatorId: posts[index].creatorId),
          ),
        ),
      ),
    );
  }
}

class _CreatorFilterSheet extends StatefulWidget {
  const _CreatorFilterSheet({required this.initial});

  final CreatorFilter initial;

  @override
  State<_CreatorFilterSheet> createState() => _CreatorFilterSheetState();
}

class _CreatorFilterSheetState extends State<_CreatorFilterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _maxRate = TextEditingController(
    text: widget.initial.maxRate?.round().toString(),
  );
  late Set<String> _types = {...widget.initial.types};
  late Set<String> _niches = {...widget.initial.niches};
  late String? _city = widget.initial.city;
  late String? _gender = widget.initial.gender;
  late String? _language = widget.initial.language;
  late String? _workType = widget.initial.workType;
  late bool _availableOnly = widget.initial.availableOnly;

  @override
  void dispose() {
    _maxRate.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatorProvider>().setFilter(
          CreatorFilter(
            query: widget.initial.query,
            types: _types,
            niches: _niches,
            city: _city,
            gender: _gender,
            language: _language,
            workType: _workType,
            maxRate: Money.parse(_maxRate.text),
            availableOnly: _availableOnly,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clear() => setState(() {
        _types = {};
        _niches = {};
        _city = null;
        _gender = null;
        _language = null;
        _workType = null;
        _availableOnly = false;
        _maxRate.clear();
      });

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    return Form(
      key: _formKey,
      child: FilterBottomSheet(
        onClear: _clear,
        onApply: _apply,
        sections: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Available now', style: context.textTheme.titleSmall),
            value: _availableOnly,
            onChanged: (value) => setState(() => _availableOnly = value),
          ),
          FilterSection(
            title: 'Creator type',
            child: MultiSelectChips(
              options: categories.creatorTypes,
              selected: _types,
              onChanged: (value) => setState(() => _types = value),
            ),
          ),
          FilterSection(
            title: 'Niche',
            child: MultiSelectChips(
              options: categories.niches,
              selected: _niches,
              onChanged: (value) => setState(() => _niches = value),
            ),
          ),
          FilterSection(
            title: 'Location',
            child: SingleSelectChips(
              options: AppConstants.cities,
              selected: _city,
              onChanged: (value) => setState(() => _city = value),
            ),
          ),
          AppTextField(
            label: 'Maximum starting rate',
            optional: true,
            controller: _maxRate,
            prefixText: 'NPR ',
            hint: '10,000',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (value) => Validators.amount(value, isRequired: false),
          ),
          FilterSection(
            title: 'Work type',
            child: SingleSelectChips(
              options: AppConstants.workTypes,
              selected: _workType,
              onChanged: (value) => setState(() => _workType = value),
            ),
          ),
          FilterSection(
            title: 'Language',
            child: SingleSelectChips(
              options: AppConstants.languages,
              selected: _language,
              onChanged: (value) => setState(() => _language = value),
            ),
          ),
          FilterSection(
            title: 'Gender',
            child: SingleSelectChips(
              options: AppConstants.genders,
              selected: _gender,
              onChanged: (value) => setState(() => _gender = value),
            ),
          ),
        ],
      ),
    );
  }
}
