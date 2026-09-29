import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categories.dart';
import '../models/transaction.dart';

class CategoriesScreen extends StatefulWidget {
  static const routeName = '/categories';

  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _controller = TextEditingController();
  final Map<String, TextEditingController> _subControllers = {};

  TextEditingController _subControllerFor(String category) {
    return _subControllers.putIfAbsent(category, () => TextEditingController());
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _subControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<Categories>().add(name);
    if (!mounted) return;

    if (success) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists or is invalid')),
      );
    }
  }

  Future<void> _addSubcategory(String category) async {
    final controller = _subControllerFor(category);
    final name = controller.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<Categories>().addSubcategory(category, name);
    if (!mounted) return;

    if (success) {
      controller.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory already exists or is invalid')),
      );
    }
  }

  Future<String?> _promptForName({
    required String title,
    required String initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editCategory(String category) async {
    final newName = await _promptForName(
      title: 'Edit category',
      initialValue: category,
    );
    if (newName == null || !mounted) return;

    final success = await context.read<Categories>().update(category, newName);
    if (!mounted) return;

    if (success) {
      // The rename cascades to the categories/subcategories tables in the
      // database, including every transaction already filed under the old
      // name. Re-fetch transactions so the app's in-memory copy picks up
      // the updated category text too.
      await context.read<Transactions>().fetchTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not rename category (name already used?)')),
      );
    }
  }

  Future<void> _editSubcategory(String category, String subcategory) async {
    final newName = await _promptForName(
      title: 'Edit subcategory',
      initialValue: subcategory,
    );
    if (newName == null || !mounted) return;

    final success = await context
        .read<Categories>()
        .updateSubcategory(category, subcategory, newName);
    if (!mounted) return;

    if (success) {
      await context.read<Transactions>().fetchTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not rename subcategory (name already used?)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Consumer<Categories>(
        builder: (context, categories, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'New category',
                          hintText: 'e.g. Subscriptions',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addCategory(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Add category',
                      onPressed: _addCategory,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: categories.categories.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    await categories.moveCategory(
                        oldIndex, newIndex - oldIndex);
                  },
                  itemBuilder: (context, index) {
                    final category = categories.categories[index];
                    final subcategories = categories.subcategoriesFor(category);
                    return ExpansionTile(
                      key: ValueKey('category-$category'),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator),
                      ),
                      title: Text(category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 'Other' is the hard-coded fallback category used
                          // elsewhere when adding a transaction, so it isn't
                          // renamed or removed from here.
                          if (category != 'Other') ...[
                            IconButton(
                              tooltip: 'Edit category',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editCategory(category),
                            ),
                            IconButton(
                              tooltip: 'Delete category',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await categories.remove(category);
                              },
                            ),
                          ],
                        ],
                      ),
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subcategories.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex -= 1;
                            await categories.moveSubcategory(
                                category, oldIndex, newIndex - oldIndex);
                          },
                          itemBuilder: (context, subIndex) {
                            final subcategory = subcategories[subIndex];
                            return ListTile(
                              key: ValueKey('subcategory-$category-$subcategory'),
                              dense: true,
                              leading: ReorderableDragStartListener(
                                index: subIndex,
                                child: const Icon(Icons.drag_indicator, size: 20),
                              ),
                              title: Text(subcategory),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit subcategory',
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () =>
                                        _editSubcategory(category, subcategory),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete subcategory',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () async {
                                      await categories.removeSubcategory(
                                          category, subcategory);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subControllerFor(category),
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'New subcategory',
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addSubcategory(category),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Add subcategory',
                                onPressed: () => _addSubcategory(category),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
