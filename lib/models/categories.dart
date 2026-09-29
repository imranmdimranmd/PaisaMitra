import 'package:flutter/foundation.dart';

import '../DBhelp/dbhelper.dart';

class Categories with ChangeNotifier {
  List<String> _categories = [];
  final Map<String, List<String>> _subcategories = {};

  List<String> get categories => List.unmodifiable(_categories);

  List<String> subcategoriesFor(String category) =>
      List.unmodifiable(_subcategories[category] ?? const []);

  Future<void> load() async {
    _categories = await DBHelper.fetchCategories();
    for (final category in _categories) {
      _subcategories[category] = await DBHelper.fetchSubcategories(category);
    }
    notifyListeners();
  }

  Future<bool> add(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || _categories.any((c) => c.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    final result = await DBHelper.insertCategory(cleaned);
    if (result == 0) return false;

    _categories = await DBHelper.fetchCategories();
    _subcategories[cleaned] = await DBHelper.fetchSubcategories(cleaned);
    notifyListeners();
    return true;
  }

  /// Renames a category everywhere it's referenced (its subcategories and
  /// any transactions already filed under it). Returns false if the new
  /// name is blank, unchanged, or clashes with an existing category.
  Future<bool> update(String oldName, String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) return false;
    if (cleaned.toLowerCase() != oldName.toLowerCase() &&
        _categories.any((c) => c.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    final success = await DBHelper.updateCategory(oldName, cleaned);
    if (!success) return false;

    _categories = await DBHelper.fetchCategories();
    final subs = _subcategories.remove(oldName);
    if (subs != null) {
      _subcategories[cleaned] = subs;
    }
    notifyListeners();
    return true;
  }

  Future<void> remove(String name) async {
    await DBHelper.deleteCategory(name);
    _categories = await DBHelper.fetchCategories();
    _subcategories.remove(name);
    notifyListeners();
  }

  Future<bool> addSubcategory(String category, String name) async {
    final cleaned = name.trim();
    final existing = _subcategories[category] ?? const [];
    if (cleaned.isEmpty ||
        existing.any((s) => s.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    final result = await DBHelper.insertSubcategory(category, cleaned);
    if (result == 0) return false;

    _subcategories[category] = await DBHelper.fetchSubcategories(category);
    notifyListeners();
    return true;
  }

  /// Renames a subcategory within [category], cascading to any transactions
  /// already filed under it. Returns false if the new name is blank,
  /// unchanged, or clashes with an existing subcategory in this category.
  Future<bool> updateSubcategory(
      String category, String oldName, String newName) async {
    final cleaned = newName.trim();
    final existing = _subcategories[category] ?? const [];
    if (cleaned.isEmpty) return false;
    if (cleaned.toLowerCase() != oldName.toLowerCase() &&
        existing.any((s) => s.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    final success =
        await DBHelper.updateSubcategory(category, oldName, cleaned);
    if (!success) return false;

    _subcategories[category] = await DBHelper.fetchSubcategories(category);
    notifyListeners();
    return true;
  }

  Future<void> removeSubcategory(String category, String name) async {
    await DBHelper.deleteSubcategory(category, name);
    _subcategories[category] = await DBHelper.fetchSubcategories(category);
    notifyListeners();
  }

  Future<void> moveCategory(int index, int direction) async {
    final target = index + direction;
    if (index < 0 || target < 0 || target >= _categories.length) return;
    final reordered = [..._categories];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    _categories = reordered;
    await DBHelper.updateCategoryOrder(_categories);
    notifyListeners();
  }

  Future<void> moveSubcategory(
      String category, int index, int direction) async {
    final items = _subcategories[category];
    if (items == null) return;
    final target = index + direction;
    if (index < 0 || target < 0 || target >= items.length) return;
    final reordered = [...items];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    _subcategories[category] = reordered;
    await DBHelper.updateSubcategoryOrder(category, reordered);
    notifyListeners();
  }
}
