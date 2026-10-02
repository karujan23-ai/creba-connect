import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/promotion.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/layout.dart';

/// "Promote Post" for brands and "Boost Profile" for creators.
///
/// Online payment is NOT implemented. Choosing a package saves a promotion
/// *request*. It becomes active only when an admin approves it; nothing here
/// ever shows a payment as successful.
class PromoteScreen extends StatefulWidget {
  const PromoteScreen({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetLabel,
  });

  final String targetId;
  final TargetType targetType;
  final String targetLabel;

  @override
  State<PromoteScreen> createState() => _PromoteScreenState();
}

class _PromoteScreenState extends State<PromoteScreen> {
  late final List<PromotionPackage> _packages =
      _isPost ? PromotionPackage.forHiringPost : PromotionPackage.forCreatorProfile;
  late PromotionPackage _selected = _packages.length > 1 ? _packages[1] : _packages.first;
  bool _isSending = false;

  bool get _isPost => widget.targetType == TargetType.hiringPost;

  Future<void> _request() async {
    setState(() => _isSending = true);
    final error = await context.read<PromotionProvider>().request(
          targetId: widget.targetId,
          targetType: widget.targetType,
          targetLabel: widget.targetLabel,
          package: _selected,
        );
    if (!mounted) return;
    setState(() => _isSending = false);
    showResult(context, error, success: 'Request saved.');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<PromotionProvider>();
    final latest = provider.latestFor(widget.targetId);
    final hasOpenRequest = latest != null &&
        (latest.status == PromotionStatus.requested ||
            latest.status == PromotionStatus.active);

    return Scaffold(
      appBar: AppBar(title: Text(_isPost ? 'Promote post' : 'Boost profile')),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 8),
          children: [
            Text(widget.targetLabel, style: context.textTheme.headlineMedium),
            const SizedBox(height: 16),
            BulletList(
              items: _isPost
                  ? const [
                      'Featured position at the top of the feed',
                      'Higher visibility in its category',
                      '"Promoted" label on the post',
                    ]
                  : const [
                      'Shown higher in creator rankings',
                      '"Boosted" label on your profile',
                    ],
            ),
            const SizedBox(height: 20),
            if (latest != null) ...[
              _RequestStatus(promotion: latest),
              const SizedBox(height: 20),
            ],
            if (!hasOpenRequest) ...[
              for (final package in _packages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PackageOption(
                    label: package.label,
                    price: settings.money(package.priceNpr),
                    selected: package == _selected,
                    onTap: () => setState(() => _selected = package),
                  ),
                ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Request promotion',
                isLoading: _isSending,
                onPressed: _request,
              ),
            ],
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: palette.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      PaymentService.isOnlinePaymentAvailable
                          ? 'You will be taken to a secure payment page.'
                          : 'Online payment is not available yet, so no money '
                              'is collected. Your request is saved and the '
                              'CreBa Connect team can approve it manually.',
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color color, String message) = switch (promotion.status) {
      PromotionStatus.requested => (
          palette.warning,
          'Your ${promotion.packageDays}-day request is waiting for review.',
        ),
      PromotionStatus.active => (
          palette.success,
          promotion.endsAt == null
              ? 'This promotion is active.'
              : 'Active until ${Dates.full(promotion.endsAt!)}.',
        ),
      PromotionStatus.expired => (palette.textMuted, 'Your last promotion has ended.'),
      PromotionStatus.rejected => (palette.danger, 'Your last request was declined.'),
    };

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label: promotion.status.label, color: color),
                const SizedBox(height: 8),
                Text(message, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
          if (promotion.status == PromotionStatus.requested)
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              compact: true,
              expand: false,
              onPressed: () async {
                final error =
                    await context.read<PromotionProvider>().cancel(promotion.id);
                if (context.mounted) {
                  showResult(context, error, success: 'Request cancelled.');
                }
              },
            ),
        ],
      ),
    );
  }
}

class _PackageOption extends StatelessWidget {
  const _PackageOption({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? palette.text : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? palette.text : palette.border,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: context.textTheme.titleMedium)),
              Text(price, style: context.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
