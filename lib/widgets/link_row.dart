import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/navigation.dart';
import 'dialogs.dart';

/// A labelled web link (website, Instagram, portfolio). Opens in the browser.
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.label, required this.value, required this.url});

  final String label;
  final String value;
  final String url;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final opened = await openLink(url);
          if (context.mounted && !opened) showSnack(context, 'Could not open the link.');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: context.palette.textMuted),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall,
                ),
              ),
              Icon(Icons.open_in_new, size: 16, color: context.palette.textMuted),
            ],
          ),
        ),
      );
}
