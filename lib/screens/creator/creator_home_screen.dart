import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/application_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/state_views.dart';
import '../shared/brand_profile_screen.dart';
import '../shared/home_header.dart';
import 'edit_creator_profile_screen.dart';
import 'my_availability_screen.dart';
import 'opportunity_tile.dart';
import 'saved_opportunities_screen.dart';

/// The creator's home: a small dashboard, then opportunities picked for them.
class CreatorHomeScreen extends StatelessWidget {
  const CreatorHomeScreen({super.key, required this.onOpenTab});

  /// Switches the bottom navigation to another tab.
  final ValueChanged<int> onOpenTab;

  static const _discoverTab = 1;
  static const _applicationsTab = 2;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final profile = context.watch<CreatorProvider>().myProfile;
    final posts = context.watch<HiringPostProvider>();
    final brands = context.watch<BrandProvider>().brands;
    final feed = posts.feed;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: pagePadding(context, top: 16).copyWith(left: 0, right: 0),
          children: [
            _padded(HomeHeader(name: user?.displayName ?? '')),
            const SizedBox(height: 24),
            if (profile != null) ...[
              _padded(_Dashboard(profile: profile, onOpenTab: onOpenTab)),
              const SizedBox(height: 32),
            ],
            if (posts.isLoading)
              const Padding(padding: EdgeInsets.all(40), child: LoadingState())
            else if (posts.error != null)
              SizedBox(height: 260, child: ErrorState(message: posts.error!))
            else if (feed.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.work_outline,
                  title: 'No opportunities yet',
                  message: 'New brand opportunities will appear here as soon '
                      'as they are posted.',
                ),
              )
            else ...[
              if (profile != null) ..._bestMatches(feed, profile),
              if (brands.isNotEmpty) ...[
                _padded(const SectionHeader(title: 'Trending brands')),
                HorizontalCards(
                  height: 150,
                  children: [
                    for (final brand in brands.take(8))
                      BrandMiniCard(
                        brand: brand,
                        onTap: () => pushScreen(
                          context,
                          BrandProfileScreen(brandId: brand.uid),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              _padded(
                SectionHeader(
                  title: 'Recently posted',
                  actionLabel: 'See all',
                  onAction: () => onOpenTab(_discoverTab),
                ),
              ),
              for (final post in feed.take(4))
                _padded(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OpportunityTile(post: post),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// The three open posts that score highest for this creator.
  List<Widget> _bestMatches(List<HiringPost> feed, CreatorProfile profile) {
    final ranked = [
      for (final post in feed) (post, MatchScorer.creatorForPost(profile, post)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final best = ranked.where((entry) => entry.$2 >= 50).take(3).toList();
    if (best.isEmpty) return const [];

    return [
      _padded(
        const SectionHeader(
          title: 'Best fit for you',
          subtitle: 'Based on your profile: type, niches, city and rate.',
        ),
      ),
      for (final (post, _) in best)
        _padded(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpportunityTile(post: post),
          ),
        ),
      const SizedBox(height: 20),
    ];
  }

  static Widget _padded(Widget child) => ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: child,
        ),
      );
}

/// Profile completeness, availability switch and headline numbers.
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.profile, required this.onOpenTab});

  final CreatorProfile profile;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final applications = context.watch<ApplicationProvider>();
    final savedCount =
        context.watch<FavoritesProvider>().countOf(TargetType.hiringPost);
    void openApplications() => onOpenTab(CreatorHomeScreen._applicationsTab);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.completeness < 100) ...[
          AppCard(
            onTap: () => pushScreen(context, EditCreatorProfileScreen(profile: profile)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile ${profile.completeness}% complete',
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.textMuted),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: profile.completeness / 100,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete profiles are shown higher to brands.',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ResponsiveGrid(
          minItemWidth: 96,
          children: [
            StatTile(
              value: '${applications.applications.length}',
              label: 'Applications',
              onTap: openApplications,
            ),
            StatTile(
              value: '${applications.countWithStatus(ApplicationStatus.shortlisted)}',
              label: 'Shortlisted',
              onTap: openApplications,
            ),
            StatTile(
              value: '${applications.countWithStatus(ApplicationStatus.selected)}',
              label: 'Selected',
              onTap: openApplications,
            ),
            StatTile(
              value: '$savedCount',
              label: 'Saved',
              onTap: () => pushScreen(context, const SavedOpportunitiesScreen()),
            ),
            StatTile(value: '${profile.viewCount}', label: 'Profile views'),
            StatTile(value: '${profile.saveCount}', label: 'Brand saves'),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.isAvailable ? 'Available for work' : 'Not available',
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      'Brands can filter by availability.',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: profile.isAvailable,
                onChanged: (value) async {
                  final error = await context
                      .read<CreatorProvider>()
                      .setAvailability(isAvailable: value);
                  if (context.mounted && error != null) showSnack(context, error);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Manage availability posts',
          variant: AppButtonVariant.secondary,
          icon: Icons.event_available_outlined,
          onPressed: () => pushScreen(context, const MyAvailabilityScreen()),
        ),
      ],
    );
  }
}
