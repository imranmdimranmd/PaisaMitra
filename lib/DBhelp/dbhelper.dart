import 'dart:async';

import '../models/transaction.dart';
import '../constants/categories.dart';

import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static const _databaseName = 'spendings.db';
  static const _databaseVersion = 5;

  static Future<sql.Database> getDatabase() async {
    final dbPath = await sql.getDatabasesPath();

    return sql.openDatabase(
      path.join(dbPath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE transactions('
          'id TEXT PRIMARY KEY,'
          'title TEXT,'
          'amount INTEGER,'
          'date TEXT,'
          'category TEXT,'
          'subcategory TEXT,'
          "type TEXT NOT NULL DEFAULT 'expense')",
        );

        await _createCategoriesTable(db);
        await _seedDefaultCategories(db);
        await _createSubcategoriesTable(db);
        await _seedDefaultSubcategories(db);
        await _createBudgetsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoriesTable(db);
          await _seedDefaultCategories(db);
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE transactions ADD COLUMN subcategory TEXT');
          } catch (_) {
            // Column already exists.
          }
          await _createSubcategoriesTable(db);
          await _seedDefaultSubcategories(db);
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
                'ALTER TABLE categories ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute(
                'ALTER TABLE subcategories ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute(
                "ALTER TABLE transactions ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'");
          } catch (_) {}
        }
        if (oldVersion < 5) {
          await _createBudgetsTable(db);
        }
      },
    );
  }

  static Future<void> _createCategoriesTable(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        isDefault INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _seedDefaultCategories(sql.Database db) async {
    for (final category in defaultCategories) {
      await db.insert(
        'categories',
        {'name': category, 'isDefault': 1},
        conflictAlgorithm: sql.ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> _createSubcategoriesTable(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        UNIQUE(category, name)
      )
    ''');
  }

  static Future<void> _seedDefaultSubcategories(sql.Database db) async {
    for (final entry in defaultSubcategories.entries) {
      for (final subcategory in entry.value) {
        await db.insert(
          'subcategories',
          {'category': entry.key, 'name': subcategory, 'isDefault': 1},
          conflictAlgorithm: sql.ConflictAlgorithm.ignore,
        );
      }
    }
  }

  static Future<List<String>> fetchCategories() async {
    final db = await DBHelper.getDatabase();
    final rows = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'sortOrder, isDefault DESC, name COLLATE NOCASE',
    );
    return rows.map((row) => row['name'] as String).toList();
  }

  static Future<int> insertCategory(String name) async {
    final db = await DBHelper.getDatabase();
    return db.insert(
      'categories',
      {'name': name.trim(), 'isDefault': 0, 'sortOrder': 999999},
      conflictAlgorithm: sql.ConflictAlgorithm.ignore,
    );
  }

  static Future<int> deleteCategory(String name) async {
    final db = await DBHelper.getDatabase();
    return db.delete(
      'categories',
      where: 'name = ? AND isDefault = 0',
      whereArgs: [name],
    );
  }

  /// Renames a category and cascades the rename to every subcategory and
  /// transaction that referenced the old name, so nothing is left pointing
  /// at a category name that no longer exists. Returns false if the new
  /// name is blank, unchanged, or already used by another category.
  static Future<bool> updateCategory(String oldName, String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == oldName.toLowerCase()) {
      return false;
    }

    final db = await DBHelper.getDatabase();

    final clash = await db.query(
      'categories',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [cleaned],
    );
    if (clash.isNotEmpty) return false;

    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'name': cleaned},
        where: 'name = ?',
        whereArgs: [oldName],
      );
      await txn.update(
        'subcategories',
        {'category': cleaned},
        where: 'category = ?',
        whereArgs: [oldName],
      );
      await txn.update(
        'transactions',
        {'category': cleaned},
        where: 'category = ?',
        whereArgs: [oldName],
      );
    });

    return true;
  }

  static Future<List<String>> fetchSubcategories(String category) async {
    final db = await DBHelper.getDatabase();
    final rows = await db.query(
      'subcategories',
      columns: ['name'],
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'sortOrder, isDefault DESC, name COLLATE NOCASE',
    );
    return rows.map((row) => row['name'] as String).toList();
  }

  static Future<int> insertSubcategory(String category, String name) async {
    final db = await DBHelper.getDatabase();
    return db.insert(
      'subcategories',
      {'category': category, 'name': name.trim(), 'isDefault': 0, 'sortOrder': 999999},
      conflictAlgorithm: sql.ConflictAlgorithm.ignore,
    );
  }

  static Future<int> deleteSubcategory(String category, String name) async {
    final db = await DBHelper.getDatabase();
    return db.delete(
      'subcategories',
      where: 'category = ? AND name = ? AND isDefault = 0',
      whereArgs: [category, name],
    );
  }

  /// Renames a subcategory within its category and cascades the rename to
  /// every transaction that referenced the old name. Returns false if the
  /// new name is blank, unchanged, or already used by another subcategory
  /// under the same category.
  static Future<bool> updateSubcategory(
      String category, String oldName, String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == oldName.toLowerCase()) {
      return false;
    }

    final db = await DBHelper.getDatabase();

    final clash = await db.query(
      'subcategories',
      where: 'category = ? AND name = ? COLLATE NOCASE',
      whereArgs: [category, cleaned],
    );
    if (clash.isNotEmpty) return false;

    await db.transaction((txn) async {
      await txn.update(
        'subcategories',
        {'name': cleaned},
        where: 'category = ? AND name = ?',
        whereArgs: [category, oldName],
      );
      await txn.update(
        'transactions',
        {'subcategory': cleaned},
        where: 'category = ? AND subcategory = ?',
        whereArgs: [category, oldName],
      );
    });

    return true;
  }

  // Inserting transaction data.
  static Future<void> insert(Transaction transaction) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'transactions',
      transaction.toMap(transaction),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateCategoryOrder(List<String> categories) async {
    final db = await DBHelper.getDatabase();
    await db.transaction((txn) async {
      for (var index = 0; index < categories.length; index++) {
        await txn.update('categories', {'sortOrder': index},
            where: 'name = ?', whereArgs: [categories[index]]);
      }
    });
  }

  static Future<void> updateSubcategoryOrder(
      String category, List<String> subcategories) async {
    final db = await DBHelper.getDatabase();
    await db.transaction((txn) async {
      for (var index = 0; index < subcategories.length; index++) {
        await txn.update('subcategories', {'sortOrder': index},
            where: 'category = ? AND name = ?',
            whereArgs: [category, subcategories[index]]);
      }
    });
  }

  static Future<void> _createBudgetsTable(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        subcategory TEXT,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        UNIQUE(category, subcategory, month, year)
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> fetchBudgets(
      int month, int year) async {
    final db = await DBHelper.getDatabase();
    return db.query('budgets', where: 'month = ? AND year = ?',
        whereArgs: [month, year], orderBy: 'category, subcategory');
  }

  static Future<void> saveBudget({required String category, String? subcategory,
      required int month, required int year, required int amount}) async {
    final db = await DBHelper.getDatabase();
    await db.insert('budgets', {
      'category': category,
      'subcategory': subcategory,
      'month': month,
      'year': year,
      'amount': amount,
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<void> deleteBudget(int id) async {
    final db = await DBHelper.getDatabase();
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Retrieving transaction data.
  static Future<List<Map<String, dynamic>>> fetch() async {
    final db = await DBHelper.getDatabase();
    return db.query('transactions');
  }

  // Deleting transactions.
  static Future<void> delete(String id) async {
    final db = await DBHelper.getDatabase();
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
