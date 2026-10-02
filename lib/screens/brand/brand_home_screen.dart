import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand_profile.dart';
import '../../models/creator_profile.dart';
import '../../models/enums.dart';
import '../../providers/application_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../utils/trending_scorer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/application_card.dart';
import '../../widgets/badges.dart';
import '../../widgets/creator_card.dart';
import '../../widgets/layout.dart';
import '../shared/creator_profile_screen.dart';
import '../shared/home_header.dart';
import '../shared/job_detail_screen.dart';
import 'applicants_screen.dart';
import 'hiring_post_form_screen.dart';
import 'saved_creators_screen.dart';
import 'verification_screen.dart';

/// The brand's home: a small dashboard, quick actions, creator suggestions
/// and recent activity.
class BrandHomeScreen extends StatelessWidget {
  const BrandHomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  static const _discoverTab = 1;
  static const _opportunitiesTab = 2;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final brand = context.watch<BrandProvider>().myBrand;
    final creators = context.watch<CreatorProvider>().creators;
    final posts = context.watch<HiringPostProvider>();
    final applications = context.watch<ApplicationProvider>();
    final savedCreators =
        context.watch<FavoritesProvider>().countOf(TargetType.creator);
    final totalViews = posts.myPosts.fold(0, (sum, post) => sum + post.viewCount);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: pagePadding(context, top: 16).copyWith(left: 0, right: 0),
          children: [
            _padded(HomeHeader(name: brand?.brandName ?? user?.displayName ?? '')),
            const SizedBox(height: 20),
            if (brand != null && !brand.isVerified) ...[
              _padded(_VerificationNotice(brand: brand)),
              const SizedBox(height: 12),
            ],
            _padded(
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Hire a creator',
                      icon: Icons.add,
                      onPressed: () =>
                          pushScreen(context, const HiringPostFormScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Discover',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => onOpenTab(_discoverTab),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _padded(
              ResponsiveGrid(
                minItemWidth: 130,
                children: [
                  StatTile(
                    value: '${posts.myOpenPosts.length}',
                    label: 'Active opportunities',
                    onTap: () => onOpenTab(_opportunitiesTab),
                  ),
                  StatTile(
                    value: '${applications.applications.length}',
                    label: 'Applications',
                    onTap: () => pushScreen(context, const ApplicantsScreen()),
                  ),
                  StatTile(
                    value: '$savedCreators',
                    label: 'Saved creators',
                    onTap: () => pushScreen(context, const SavedCreatorsScreen()),
                  ),
                  StatTile(value: '$totalViews', label: 'Post views'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (brand != null) ..._bestFit(context, creators, brand),
            ..._creatorRow(
              context,
              title: 'Trending creators',
              subtitle: 'Ranked by profile views, saves and recent activity.',
              creators: TrendingScorer.trending(creators),
            ),
            ..._creatorRow(
              context,
              title: 'Rising creators',
              subtitle: 'Joined in the last 30 days.',
              creators: TrendingScorer.rising(creators),
            ),
            if (brand != null)
              for (final niche
                  in (AppConstants.categoryToNiches[brand.category] ?? const ['Fashion'])
                      .take(1))
                ..._creatorRow(
                  context,
                  title: 'Popular in $niche',
                  creators: TrendingScorer.popularIn(creators, niche),
                ),
            ..._creatorRow(
              context,
              title: 'Recently active',
              creators: TrendingScorer.recentlyActive(creators),
            ),
            if (applications.applications.isNotEmpty) ...[
              _padded(
                SectionHeader(
                  title: 'Recent applications',
                  actionLabel: 'See all',
                  onAction: () => pushScreen(context, const ApplicantsScreen()),
                ),
              ),
              for (final application in applications.applications.take(3))
                _padded(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ApplicationCard(
                      application: application,
                      forBrand: true,
                      onTap: () => pushScreen(context, const ApplicantsScreen()),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            if (posts.myPosts.isNotEmpty) ...[
              _padded(
                SectionHeader(
                  title: 'Post performance',
                  actionLabel: 'Manage',
                  onAction: () => onOpenTab(_opportunitiesTab),
                ),
              ),
              _padded(
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (final (index, post) in posts.myPosts.take(5).indexed) ...[
                        if (index > 0) Divider(color: context.palette.border),
                        InkWell(
                          onTap: () => pushScreen(context, JobDetailScreen(post: post)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${post.viewCount} views · '
                                  '${post.applicationCount} applications',
                                  style: context.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Creators with the highest Best Fit score for this brand.
  List<Widget> _bestFit(
    BuildContext context,
    List<CreatorProfile> creators,
    BrandProfile brand,
  ) {
    final ranked = [
      for (final creator in creators)
        (creator, MatchScorer.creatorForBrand(creator, brand)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final best = ranked.where((entry) => entry.$2 >= 50).take(10).toList();
    if (best.isEmpty) return const [];

    return [
      _padded(
        const SectionHeader(
          title: 'Best fit for you',
          subtitle: 'Based on your requirements: category, city and availability.',
        ),
      ),
      HorizontalCards(
        children: [
          for (final (creator, score) in best)
            CreatorMiniCard(
              creator: creator,
              matchPercent: score,
              onTap: () => pushScreen(
                context,
                CreatorProfileScreen(creatorId: creator.uid),
              ),
            ),
        ],
      ),
      const SizedBox(height: 32),
    ];
  }

  List<Widget> _creatorRow(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<CreatorProfile> creators,
  }) {
    if (creators.isEmpty) return const [];
    return [
      _padded(
        SectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: 'See all',
          onAction: () => onOpenTab(_discoverTab),
        ),
      ),
      HorizontalCards(
        children: [
          for (final creator in creators)
            CreatorMiniCard(
              creator: creator,
              onTap: () => pushScreen(
                context,
                CreatorProfileScreen(creatorId: creator.uid),
              ),
            ),
        ],
      ),
      const SizedBox(height: 32),
    ];
  }

  static Widget _padded(Widget child) => ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: child,
        ),
      );
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice({required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) {
    final isRejected = brand.verificationStatus == VerificationStatus.rejected;
    return AppCard(
      onTap: () => pushScreen(context, const VerificationScreen()),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VerificationStatusBadge(status: brand.verificationStatus),
                const SizedBox(height: 8),
                Text(
                  isRejected
                      ? 'Your verification was not approved. Tap to review and resubmit.'
                      : 'Verified businesses get a badge creators trust. '
                          'Tap to check your details.',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.textMuted),
        ],
      ),
    );
  }
}
