import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creator_profile.dart';
import '../../models/enums.dart';
import '../../providers/brand_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/match_scorer.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';
import '../../widgets/link_row.dart';
import '../../widgets/price_display.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/state_views.dart';
import '../brand/invite_sheet.dart';
import '../chat/chat_screen.dart';
import '../creator/edit_creator_profile_screen.dart';
import '../creator/my_availability_screen.dart';
import '../promotion/promote_screen.dart';
import '../settings/settings_screen.dart';

/// A creator's profile. The same screen serves three viewers:
/// the creator themselves (edit actions), a brand (contact and save actions)
/// and an admin (read only).
class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key, required this.creatorId, this.isTab = false});

  final String creatorId;

  /// True when shown as the creator's own "Profile" tab.
  final bool isTab;

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  Future<CreatorProfile?>? _loading;

  @override
  void initState() {
    super.initState();
    final isOwn = context.read<UserProvider>().user?.uid == widget.creatorId;
    if (!isOwn) {
      final provider = context.read<CreatorProvider>();
      _loading = provider.getById(widget.creatorId);
      provider.recordView(widget.creatorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Own profile: shown live from the provider, so edits appear at once.
    if (_loading == null) {
      final provider = context.watch<CreatorProvider>();
      return _scaffold(
        context,
        profile: provider.myProfile,
        isLoading: !provider.myProfileLoaded,
        isOwn: true,
      );
    }
    return FutureBuilder<CreatorProfile?>(
      future: _loading,
      builder: (context, snapshot) => _scaffold(
        context,
        profile: snapshot.data,
        isLoading: snapshot.connectionState != ConnectionState.done,
        isOwn: false,
      ),
    );
  }

  Widget _scaffold(
    BuildContext context, {
    required CreatorProfile? profile,
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
          else if (profile != null && viewer != null && !viewer.isAdmin)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (_) => ReportSheet.show(
                context,
                targetId: profile.uid,
                targetType: TargetType.creator,
                targetLabel: profile.fullName,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const LoadingState()
          : profile == null
              ? const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Profile not found',
                  message: 'This creator may have removed their profile.',
                )
              : ContentWidth(
                  child: ListView(
                    padding: pagePadding(context, top: 8),
                    children: [
                      _Header(profile: profile),
                      const SizedBox(height: 20),
                      if (isOwn)
                        _OwnerActions(profile: profile)
                      else if (viewer?.isBrand ?? false)
                        _BrandActions(profile: profile),
                      const SizedBox(height: 24),
                      _Stats(profile: profile, isOwn: isOwn),
                      ..._details(context, profile),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _details(BuildContext context, CreatorProfile profile) {
    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Overline(title), const SizedBox(height: 12), child],
          ),
        );
    final socials = <(String, String, String)>[
      if (profile.instagram != null)
        ('Instagram', '@${profile.instagram}', 'https://instagram.com/${profile.instagram}'),
      if (profile.tiktok != null)
        ('TikTok', '@${profile.tiktok}', 'https://www.tiktok.com/@${profile.tiktok}'),
      if (profile.youtube != null)
        ('YouTube', '@${profile.youtube}', 'https://www.youtube.com/@${profile.youtube}'),
    ];

    return [
      if (profile.bio.isNotEmpty)
        section('About', Text(profile.bio, style: context.textTheme.bodyLarge)),
      if (profile.niches.isNotEmpty) section('Niches', ChipWrap(labels: profile.niches)),
      if (profile.workTypes.isNotEmpty)
        section('Available for', BulletList(items: profile.workTypes)),
      if (profile.startingRate != null)
        section(
          'Starting from',
          PriceDisplay(
            amount: profile.startingRate!,
            style: context.textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
        ),
      if (profile.skills.isNotEmpty) section('Skills', ChipWrap(labels: profile.skills)),
      if (profile.languages.isNotEmpty)
        section(
          'Languages',
          Text(profile.languages.join(', '), style: context.textTheme.bodyLarge),
        ),
      if (profile.previousCollaborations.isNotEmpty)
        section(
          'Previous collaborations',
          BulletList(items: profile.previousCollaborations),
        ),
      if (socials.isNotEmpty || profile.portfolioUrl != null)
        section(
          'Links',
          Column(
            children: [
              for (final (label, handle, url) in socials)
                LinkRow(label: label, value: handle, url: url),
              if (profile.portfolioUrl != null)
                LinkRow(
                  label: 'Portfolio',
                  value: profile.portfolioUrl!,
                  url: profile.portfolioUrl!,
                ),
            ],
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(name: profile.fullName, imageUrl: profile.photoUrl, size: 88),
        const SizedBox(height: 18),
        const Overline('Creator'),
        const SizedBox(height: 6),
        Text(profile.fullName, style: context.textTheme.displaySmall),
        const SizedBox(height: 6),
        if (profile.creatorTypes.isNotEmpty)
          Text(profile.typeLine, style: context.textTheme.titleMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (profile.city.isNotEmpty)
              MetaItem(icon: Icons.place_outlined, text: profile.city),
            StatusBadge(
              label: profile.isAvailable ? 'Available' : 'Not available',
              color: profile.isAvailable ? palette.success : null,
            ),
            if (profile.isBoosted) StatusBadge(label: 'Boosted', color: palette.accent),
            if (profile.isDemo) const StatusBadge(label: 'Sample profile'),
          ],
        ),
      ],
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit profile',
                  onPressed: () =>
                      pushScreen(context, EditCreatorProfileScreen(profile: profile)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Availability',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => pushScreen(context, const MyAvailabilityScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Boost profile',
            icon: Icons.trending_up,
            variant: AppButtonVariant.secondary,
            onPressed: () => pushScreen(
              context,
              PromoteScreen(
                targetId: profile.uid,
                targetType: TargetType.creator,
                targetLabel: profile.fullName,
              ),
            ),
          ),
        ],
      );
}

class _BrandActions extends StatelessWidget {
  const _BrandActions({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandProvider>().myBrand;
    final isSaved = context.watch<FavoritesProvider>().isSaved(profile.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (brand != null) ...[
          Row(
            children: [
              MatchBadge(percent: MatchScorer.creatorForBrand(profile, brand)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Based on your requirements',
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Message',
                onPressed: () => pushScreen(
                  context,
                  ChatScreen(otherId: profile.uid, otherName: profile.fullName),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Invite',
                variant: AppButtonVariant.secondary,
                onPressed: () => InviteSheet.show(context, profile),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: isSaved ? 'Saved' : 'Save creator',
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final error = await context
                      .read<FavoritesProvider>()
                      .toggle(profile.uid, TargetType.creator);
                  if (context.mounted && error != null) showSnack(context, error);
                },
              ),
            ),
            if (profile.portfolioUrl != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Portfolio',
                  icon: Icons.open_in_new,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final opened = await openLink(profile.portfolioUrl!);
                    if (context.mounted && !opened) {
                      showSnack(context, 'Could not open the link.');
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.profile, required this.isOwn});

  final CreatorProfile profile;
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: StatTile(value: '${profile.viewCount}', label: 'Profile views'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(value: '${profile.saveCount}', label: 'Saves'),
          ),
          if (isOwn) ...[
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(value: '${profile.completeness}%', label: 'Complete'),
            ),
          ],
        ],
      );
}
