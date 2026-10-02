import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A search field with an optional filter button. The button shows how many
/// filters are switched on.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialText = '',
    this.onFilterTap,
    this.activeFilters = 0,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialText;
  final VoidCallback? onFilterTap;
  final int activeFilters;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasFilters = widget.activeFilters > 0;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              widget.onChanged(value);
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            style: context.textTheme.bodyLarge,
            cursorColor: palette.text,
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: palette.textMuted),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: Icon(Icons.close, size: 18, color: palette.textMuted),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: hasFilters ? 'Filters, ${widget.activeFilters} active' : 'Filters',
            child: Material(
              color: hasFilters ? palette.primary : palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                side: BorderSide(color: hasFilters ? palette.primary : palette.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onFilterTap,
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 19,
                          color: hasFilters ? palette.onPrimary : palette.text,
                        ),
                        if (hasFilters) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${widget.activeFilters}',
                            style: context.textTheme.labelLarge
                                ?.copyWith(color: palette.onPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
