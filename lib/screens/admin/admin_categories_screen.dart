import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../services/category_service.dart';
import '../../theme/app_palette.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/layout.dart';

/// Admin: edit the option lists used in pickers across the app.
class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ContentWidth(
        child: ListView(
          padding: pagePadding(context, top: 8),
          children: [
            _CategoryEditor(
              title: 'Creator types',
              name: CategoryService.creatorTypes,
              items: categories.creatorTypes,
            ),
            _CategoryEditor(
              title: 'Niches',
              name: CategoryService.niches,
              items: categories.niches,
            ),
            _CategoryEditor(
              title: 'Business categories',
              name: CategoryService.businessCategories,
              items: categories.businessCategories,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.title, required this.name, required this.items});

  final String title;

  /// The Firestore document name for this list.
  final String name;
  final List<String> items;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _newItem = TextEditingController();

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> items) async {
    final error = await context.read<CategoryProvider>().save(widget.name, items);
    if (mounted && error != null) showSnack(context, error);
  }

  void _add() {
    final value = _newItem.text.trim();
    if (value.isEmpty) return;
    final exists = widget.items.any((item) => item.toLowerCase() == value.toLowerCase());
    if (exists) {
      showSnack(context, '"$value" is already in the list.');
      return;
    }
    _newItem.clear();
    _save([...widget.items, value]);
  }

  void _remove(String item) {
    if (widget.items.length <= 1) {
      showSnack(context, 'A list needs at least one option.');
      return;
    }
    _save(widget.items.where((existing) => existing != item).toList());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: context.textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.items)
                Container(
                  padding: const EdgeInsets.only(left: 13, right: 4),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item, style: context.textTheme.labelMedium),
                      IconButton(
                        tooltip: 'Remove $item',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close, size: 16, color: palette.textMuted),
                        onPressed: () => _remove(item),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItem,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    hintText: 'Add an option',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Add',
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: _add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
