import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/hiring_post.dart';
import '../providers/settings_provider.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';

/// Shows an amount in the currency chosen in Settings.
///
/// When that differs from the currency the amount was entered in, the value
/// is converted with the app's fixed rate, marked "≈", and the original is
/// shown beside it so nobody mistakes an estimate for the real price.
class PriceDisplay extends StatelessWidget {
  const PriceDisplay({
    super.key,
    required this.amount,
    this.currency = Currency.npr,
    this.prefix,
    this.style,
  });

  final num amount;

  /// The currency [amount] was entered in.
  final Currency currency;

  /// Text before the amount, e.g. "From".
  final String? prefix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final preferred = context.watch<SettingsProvider>().currency;
    final main = Money.display(amount, currency, preferred);
    final base = style ?? context.textTheme.titleSmall;
    final isConverted = preferred != currency;

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(
              text: '$prefix ',
              style: base?.copyWith(
                color: context.palette.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          TextSpan(text: main),
          if (isConverted)
            TextSpan(
              text: '  ${Money.format(amount, currency)}',
              style: context.textTheme.bodySmall,
            ),
        ],
      ),
      style: base,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A hiring post's budget as text: "NPR 15,000", "NPR 10,000–20,000" or
/// "Negotiable". Converted amounts are marked "≈".
String budgetText(HiringPost post, Currency preferred) {
  String show(num amount) => Money.display(amount, post.currency, preferred);

  switch (post.budgetType) {
    case BudgetType.negotiable:
      return 'Negotiable';
    case BudgetType.fixed:
      return post.budgetMin == null ? 'Negotiable' : show(post.budgetMin!);
    case BudgetType.range:
      final min = post.budgetMin;
      final max = post.budgetMax;
      if (min == null && max == null) return 'Negotiable';
      if (min == null || max == null) return show((min ?? max)!);
      // "NPR 10,000–20,000": the currency code is written once.
      final upper = show(max).replaceFirst('≈ ', '').replaceFirst('${preferred.code} ', '');
      return '${show(min)}–$upper';
  }
}

/// [budgetText] as a widget that follows the Settings currency.
class BudgetDisplay extends StatelessWidget {
  const BudgetDisplay({super.key, required this.post, this.style});

  final HiringPost post;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final preferred = context.watch<SettingsProvider>().currency;
    return Text(
      budgetText(post, preferred),
      style: style ?? context.textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
