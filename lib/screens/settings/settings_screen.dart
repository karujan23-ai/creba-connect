import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/app_config.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../brand/edit_brand_profile_screen.dart';
import '../creator/edit_creator_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../promotion/plans_screen.dart';
import 'info_screen.dart';

/// Settings: account, appearance, currency, and information pages.
///
/// [extraSections] lets the admin area add its own tools to the same screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.extraSections = const []});

  final List<Widget> extraSections;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final email = context.watch<AuthProvider>().email ?? user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 8),
          children: [
            SettingsGroup(
              title: 'Account',
              children: [
                SettingsRow(label: 'Signed in as', value: email),
                if (user != null) SettingsRow(label: 'Account type', value: user.role.label),
                if (user != null && !user.isAdmin) const _EditProfileRow(),
                if (user != null && !user.isAdmin)
                  SettingsRow(
                    label: 'Plan',
                    onTap: () => pushScreen(context, const PlansScreen()),
                  ),
                SettingsRow(
                  label: 'Notifications',
                  onTap: () => pushScreen(context, const NotificationsScreen()),
                ),
              ],
            ),
            const _ThemeSetting(),
            const _CurrencySetting(),
            ...extraSections,
            SettingsGroup(
              title: 'Information',
              children: [
                SettingsRow(
                  label: 'Privacy',
                  onTap: () => pushScreen(context, InfoScreen.privacy),
                ),
                SettingsRow(
                  label: 'Help',
                  onTap: () => pushScreen(context, InfoScreen.help),
                ),
                SettingsRow(
                  label: 'About',
                  onTap: () => pushScreen(context, InfoScreen.about),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Sign out?',
                  message: 'You will need your email and password to sign in again.',
                  confirmLabel: 'Sign out',
                );
                if (confirmed && context.mounted) await signOutAndReset(context);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${AppConstants.appName} · version 1.0.0',
                style: context.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the right profile editor for the signed-in role.
class _EditProfileRow extends StatelessWidget {
  const _EditProfileRow();

  @override
  Widget build(BuildContext context) {
    final creator = context.watch<CreatorProvider>().myProfile;
    final brand = context.watch<BrandProvider>().myBrand;
    final Widget? editor = creator != null
        ? EditCreatorProfileScreen(profile: creator)
        : (brand != null ? EditBrandProfileScreen(brand: brand) : null);

    return SettingsRow(
      label: 'Profile',
      onTap: editor == null ? null : () => pushScreen(context, editor),
    );
  }
}

/// Light / Dark / System. The choice is applied at once and saved on the
/// device by `ThemeProvider`.
class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  static const _labels = {
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
    ThemeMode.system: 'System',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return SettingsGroup(
      title: 'Theme',
      padded: true,
      children: [
        SingleSelectChips(
          options: _labels.values.toList(),
          selected: _labels[theme.mode],
          allowClear: false,
          onChanged: (label) => theme.setMode(
            _labels.entries.firstWhere((entry) => entry.value == label).key,
          ),
        ),
      ],
    );
  }
}

class _CurrencySetting extends StatelessWidget {
  const _CurrencySetting();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return SettingsGroup(
      title: 'Currency',
      padded: true,
      children: [
        SingleSelectChips(
          options: [for (final currency in Currency.values) currency.code],
          selected: settings.currency.code,
          allowClear: false,
          onChanged: (code) => settings.setCurrency(Currency.fromCode(code)),
        ),
        const SizedBox(height: 10),
        Text(
          'Prices are entered in NPR. USD amounts are approximate, using a '
          'fixed rate of 1 USD ≈ NPR ${AppConfig.nprPerUsd.round()}.',
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A titled card of settings rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.padded = false,
  });

  final String title;
  final List<Widget> children;

  /// Adds inner padding, for content that is not a list of [SettingsRow]s.
  final bool padded;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Overline(title),
            const SizedBox(height: 10),
            AppCard(
              padding: padded ? const EdgeInsets.all(16) : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, child) in children.indexed) ...[
                    if (index > 0 && !padded) Divider(color: context.palette.border),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

/// One line in a [SettingsGroup]: a label with either a value or a chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Text(label, style: context.textTheme.bodyLarge),
              const SizedBox(width: 16),
              Expanded(
                child: value == null
                    ? const SizedBox.shrink()
                    : Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: context.palette.textMuted),
                      ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: context.palette.textMuted),
            ],
          ),
        ),
      );
}
