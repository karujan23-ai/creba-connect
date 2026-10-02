import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand_profile.dart';
import '../../models/enums.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/badges.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';
import '../../widgets/link_row.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/state_views.dart';

/// Admin: review brands and mark them verified or rejected.
///
/// This is a manual, in-app decision. The app does not check the PAN with
/// any government system and never claims to.
class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  static const _tabs = [
    VerificationStatus.pending,
    VerificationStatus.verified,
    VerificationStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verification'),
          bottom: TabBar(
            tabs: [
              for (final status in _tabs)
                Tab(
                  text: '${status.name[0].toUpperCase()}${status.name.substring(1)} '
                      '(${admin.brandsWithStatus(status).length})',
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final status in _tabs)
              _BrandList(brands: admin.brandsWithStatus(status)),
          ],
        ),
      ),
    );
  }
}

class _BrandList extends StatelessWidget {
  const _BrandList({required this.brands});

  final List<BrandProfile> brands;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const EmptyState(
        icon: Icons.verified_outlined,
        title: 'Nothing in this list',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: pagePadding(context, top: 16),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            _ReviewCard(key: ValueKey(brands[index].uid), brand: brands[index]),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({super.key, required this.brand});

  final BrandProfile brand;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  late final Future<BrandVerification?> _verification =
      context.read<AdminProvider>().verificationOf(widget.brand.uid);
  bool _isWorking = false;

  Future<void> _decide(VerificationStatus status) async {
    String? reason;
    if (status == VerificationStatus.rejected) {
      reason = await showAppSheet<String>(context, builder: (_) => const _RejectSheet());
      if (reason == null || !mounted) return;
    }
    setState(() => _isWorking = true);
    final error = await context.read<AdminProvider>().setVerification(
          widget.brand,
          status,
          rejectionReason: reason,
        );
    if (!mounted) return;
    setState(() => _isWorking = false);
    showResult(
      context,
      error,
      success: status == VerificationStatus.verified
          ? '${widget.brand.brandName} verified.'
          : '${widget.brand.brandName} rejected.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: brand.brandName,
                imageUrl: brand.logoUrl,
                size: 44,
                square: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandNameLine(
                      name: brand.brandName,
                      isVerified: brand.isVerified,
                      style: context.textTheme.titleMedium,
                    ),
                    Text(
                      [brand.category, brand.city].where((v) => v.isNotEmpty).join(' · '),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (brand.isDemo) const StatusBadge(label: 'Sample'),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<BrandVerification?>(
            future: _verification,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Text('Loading PAN details…', style: context.textTheme.bodySmall);
              }
              final details = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Detail(
                    label: 'PAN',
                    value: (details?.hasPan ?? false) ? details!.panNumber : 'Not submitted',
                  ),
                  if (details?.submittedAt != null)
                    _Detail(label: 'Submitted', value: Dates.full(details!.submittedAt!)),
                  if (details?.rejectionReason != null)
                    _Detail(label: 'Last rejection', value: details!.rejectionReason!),
                  if (details?.panDocumentUrl != null)
                    LinkRow(
                      label: 'Document',
                      value: details!.panDocumentUrl!,
                      url: details.panDocumentUrl!,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Divider(color: palette.border),
          const SizedBox(height: 12),
          Row(
            children: [
              if (brand.verificationStatus != VerificationStatus.rejected)
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    variant: AppButtonVariant.danger,
                    compact: true,
                    onPressed: _isWorking ? null : () => _decide(VerificationStatus.rejected),
                  ),
                ),
              if (brand.verificationStatus == VerificationStatus.pending)
                const SizedBox(width: 12),
              if (brand.verificationStatus != VerificationStatus.verified)
                Expanded(
                  child: AppButton(
                    label: 'Verify',
                    compact: true,
                    isLoading: _isWorking,
                    onPressed: () => _decide(VerificationStatus.verified),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(
                label,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: context.palette.textMuted),
              ),
            ),
            Expanded(child: Text(value, style: context.textTheme.titleSmall)),
          ],
        ),
      );
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
        title: 'Reject verification',
        subtitle: 'The brand will see this reason and can submit again.',
        footer: AppButton(
          label: 'Reject',
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
        ),
        child: AppTextField(
          label: 'Reason',
          optional: true,
          controller: _reason,
          hint: 'PAN number does not match the business name',
          maxLines: 3,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
        ),
      );
}
