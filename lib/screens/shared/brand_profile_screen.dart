import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand_profile.dart';
import '../../models/enums.dart';
import '../../models/hiring_post.dart';
import '../../providers/brand_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hiring_post_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/link_row.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/state_views.dart';
import '../brand/edit_brand_profile_screen.dart';
import '../brand/verification_screen.dart';
import '../chat/chat_screen.dart';
import '../creator/opportunity_tile.dart';
import '../settings/settings_screen.dart';

/// A brand's profile. The brand itself sees edit and verification actions;
/// creators see the brand's open opportunities and can contact or save it.
class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key, required this.brandId, this.isTab = false});

  final String brandId;

  /// True when shown as the brand's own "Profile" tab.
  final bool isTab;

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  Future<BrandProfile?>? _loading;
  Future<List<HiringPost>>? _openPosts;

  @override
  void initState() {
    super.initState();
    final isOwn = context.read<UserProvider>().user?.uid == widget.brandId;
    if (!isOwn) {
      final provider = context.read<BrandProvider>();
      _loading = provider.getById(widget.brandId);
      _openPosts = context.read<HiringPostProvider>().openPostsOf(widget.brandId);
      provider.recordView(widget.brandId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Own profile: shown live from the provider, so edits appear at once.
    if (_loading == null) {
      final provider = context.watch<BrandProvider>();
      return _scaffold(
        context,
        brand: provider.myBrand,
        isLoading: !provider.myBrandLoaded,
        isOwn: true,
      );
    }
    return FutureBuilder<BrandProfile?>(
      future: _loading,
      builder: (context, snapshot) => _scaffold(
        context,
        brand: snapshot.data,
        isLoading: snapshot.connectionState != ConnectionState.done,
        isOwn: false,
      ),
    );
  }

  Widget _scaffold(
    BuildContext context, {
    required BrandProfile? brand,
    required bool isLoading,
    required bool isOwn,
  }) {
    final viewer = context.watch<UserProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: widget.isTab ? const Text('Profile') : null,
        actions: [
          if (isOwn)
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => pushScreen(context, const SettingsScreen()),
            )
          else if (brand != null && viewer != null && !viewer.isAdmin)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (_) => ReportSheet.show(
                context,
                targetId: brand.uid,
                targetType: TargetType.brand,
                targetLabel: brand.brandName,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const LoadingState()
          : brand == null
              ? const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Brand not found',
                  message: 'This brand may have removed its profile.',
                )
              : ContentWidth(
                  child: ListView(
                    padding: pagePadding(context, top: 8),
                    children: [
                      _Header(brand: brand),
                      const SizedBox(height: 20),
                      if (isOwn)
                        _OwnerActions(brand: brand)
                      else if (viewer?.isCreator ?? false)
                        _CreatorActions(brand: brand),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: '${brand.viewCount}',
                              label: 'Profile views',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(value: '${brand.saveCount}', label: 'Saves'),
                          ),
                        ],
                      ),
                      if (brand.description.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Overline('About'),
                        const SizedBox(height: 12),
                        Text(brand.description, style: context.textTheme.bodyLarge),
                      ],
                      if (brand.website != null || brand.instagram != null) ...[
                        const SizedBox(height: 28),
                        const Overline('Links'),
                        const SizedBox(height: 4),
                        if (brand.website != null)
                          LinkRow(
                            label: 'Website',
                            value: brand.website!,
                            url: brand.website!,
                          ),
                        if (brand.instagram != null)
                          LinkRow(
                            label: 'Instagram',
                            value: '@${brand.instagram}',
                            url: 'https://instagram.com/${brand.instagram}',
                          ),
                      ],
                      if (!isOwn)
                        _OpenPosts(
                          posts: _openPosts,
                          viewerIsCreator: viewer?.isCreator ?? false,
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            name: brand.brandName,
            imageUrl: brand.logoUrl,
            size: 84,
            square: true,
          ),
          const SizedBox(height: 18),
          const Overline('Brand'),
          const SizedBox(height: 6),
          Text(brand.brandName, style: context.textTheme.displaySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (brand.isVerified)
                const VerifiedBadge(showLabel: true)
              else
                VerificationStatusBadge(status: brand.verificationStatus),
              if (brand.isDemo) const StatusBadge(label: 'Sample business'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            [brand.category, brand.city].where((v) => v.isNotEmpty).join(' · '),
            style: context.textTheme.titleMedium,
          ),
        ],
      );
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Edit profile',
              onPressed: () => pushScreen(context, EditBrandProfileScreen(brand: brand)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Verification',
              variant: AppButtonVariant.secondary,
              onPressed: () => pushScreen(context, const VerificationScreen()),
            ),
          ),
        ],
      );
}

class _CreatorActions extends StatelessWidget {
  const _CreatorActions({required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) {
    final isSaved = context.watch<FavoritesProvider>().isSaved(brand.uid);
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Contact',
            onPressed: () => pushScreen(
              context,
              ChatScreen(otherId: brand.uid, otherName: brand.brandName),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: isSaved ? 'Saved' : 'Save',
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final error = await context
                  .read<FavoritesProvider>()
                  .toggle(brand.uid, TargetType.brand);
              if (context.mounted && error != null) showSnack(context, error);
            },
          ),
        ),
      ],
    );
  }
}

class _OpenPosts extends StatelessWidget {
  const _OpenPosts({required this.posts, required this.viewerIsCreator});

  final Future<List<HiringPost>>? posts;
  final bool viewerIsCreator;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<HiringPost>>(
        future: posts,
        builder: (context, snapshot) {
          final open = snapshot.data ?? const <HiringPost>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Active opportunities',
                subtitle: snapshot.connectionState == ConnectionState.done
                    ? '${open.length} open'
                    : 'Loading…',
              ),
              if (snapshot.connectionState == ConnectionState.done && open.isEmpty)
                Text(
                  'This brand has no open opportunities right now.',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: context.palette.textMuted),
                ),
              if (viewerIsCreator)
                for (final post in open)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OpportunityTile(post: post),
                  ),
            ],
          );
        },
      );
}
