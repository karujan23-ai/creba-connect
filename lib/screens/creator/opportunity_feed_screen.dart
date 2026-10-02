import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/filters.dart';
import '../../providers/category_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import 'opportunity_tile.dart';

/// The creator's "Discover" tab: a live, vertically scrolling feed of open
/// opportunities with search and filters.
class OpportunityFeedScreen extends StatelessWidget {
  const OpportunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<HiringPostProvider>();
    final results = posts.filteredFeed;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 12),
              child: AppSearchBar(
                hint: 'Search title, brand, city…',
                onChanged: posts.setQuery,
                activeFilters: posts.filter.activeCount,
                onFilterTap: () => showAppSheet<void>(
                  context,
                  builder: (_) => _JobFilterSheet(initial: posts.filter),
                ),
              ),
            ),
            Expanded(
              child: posts.isLoading
                  ? const LoadingState()
                  : posts.error != null
                      ? ErrorState(message: posts.error!)
                      : results.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off,
                              title: 'No opportunities found',
                              message: posts.feed.isEmpty
                                  ? 'Nothing has been posted yet. Check back soon.'
                                  : 'Try a different search or clear your filters.',
                              actionLabel:
                                  posts.filter.activeCount > 0 ? 'Clear filters' : null,
                              onAction: posts.clearFilter,
                            )
                          : ListView.separated(
                              padding: pagePadding(context, top: 4),
                              itemCount: results.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, index) => OpportunityTile(
                                key: ValueKey(results[index].id),
                                post: results[index],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobFilterSheet extends StatefulWidget {
  const _JobFilterSheet({required this.initial});

  final JobFilter initial;

  @override
  State<_JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<_JobFilterSheet> {
  late Set<String> _niches = {...widget.initial.niches};
  late String? _creatorType = widget.initial.creatorType;
  late String? _city = widget.initial.city;
  late String? _workType = widget.initial.workType;
  late bool _remoteOnly = widget.initial.remoteOnly;

  void _apply() {
    context.read<HiringPostProvider>().setFilter(
          JobFilter(
            query: widget.initial.query,
            niches: _niches,
            creatorType: _creatorType,
            city: _city,
            workType: _workType,
            remoteOnly: _remoteOnly,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clear() => setState(() {
        _niches = {};
        _creatorType = null;
        _city = null;
        _workType = null;
        _remoteOnly = false;
      });

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    return FilterBottomSheet(
      onClear: _clear,
      onApply: _apply,
      sections: [
        FilterSection(
          title: 'Looking for',
          child: SingleSelectChips(
            options: categories.creatorTypes,
            selected: _creatorType,
            onChanged: (value) => setState(() => _creatorType = value),
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
        FilterSection(
          title: 'Work type',
          child: SingleSelectChips(
            options: AppConstants.workTypes,
            selected: _workType,
            onChanged: (value) => setState(() => _workType = value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Remote only', style: context.textTheme.titleSmall),
          value: _remoteOnly,
          onChanged: (value) => setState(() => _remoteOnly = value),
        ),
      ],
    );
  }
}
