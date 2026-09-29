import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../DBhelp/dbhelper.dart';
import '../models/transaction.dart';

class ImportSummary {
  final int imported;
  final int duplicatesSkipped;
  final int invalidRowsSkipped;

  const ImportSummary({
    required this.imported,
    required this.duplicatesSkipped,
    required this.invalidRowsSkipped,
  });
}

class ImportService {
  /// Reads an .xlsx file that follows the app's export column order
  /// (Type, Category, Subcategory, Date, Time, Name, Amount) and inserts
  /// every row that is not an exact duplicate (same category, subcategory,
  /// name, amount and date/time) of an existing transaction.
  static Future<ImportSummary> importTransactionsFromExcel(
    String filePath,
    List<Transaction> existingTransactions,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final workbook = Excel.decodeBytes(bytes);

    var imported = 0;
    var duplicatesSkipped = 0;
    var invalidRowsSkipped = 0;

    if (workbook.tables.isEmpty) {
      return const ImportSummary(
          imported: 0, duplicatesSkipped: 0, invalidRowsSkipped: 0);
    }

    final sheetName = workbook.tables.keys.contains('Transactions')
        ? 'Transactions'
        : workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName];

    if (sheet == null || sheet.maxRows < 2) {
      return const ImportSummary(
          imported: 0, duplicatesSkipped: 0, invalidRowsSkipped: 0);
    }

    final existingKeys = existingTransactions.map(_keyFor).toSet();

    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];

      final category = _cellText(row, 1);
      final subcategory = _cellText(row, 2);
      final name = _cellText(row, 5);
      final amount = _cellAmount(row, 6);
      final date = _cellDateTime(row, 3, 4);

      if (category.isEmpty || name.isEmpty || amount == null || date == null) {
        invalidRowsSkipped++;
        continue;
      }

      await DBHelper.insertCategory(category);
      if (subcategory.isNotEmpty) {
        await DBHelper.insertSubcategory(category, subcategory);
      }

      final transaction = Transaction(
        id: '${date.microsecondsSinceEpoch}_$r',
        title: name,
        amount: amount,
        date: date,
        category: category,
        subcategory: subcategory.isEmpty ? null : subcategory,
      );

      final key = _keyFor(transaction);
      if (!existingKeys.add(key)) {
        duplicatesSkipped++;
        continue;
      }

      await DBHelper.insert(transaction);
      imported++;
    }

    return ImportSummary(
      imported: imported,
      duplicatesSkipped: duplicatesSkipped,
      invalidRowsSkipped: invalidRowsSkipped,
    );
  }

  /// Key used to detect rows that duplicate an existing transaction across
  /// every exported column (category, subcategory, name, amount, date/time).
  static String _keyFor(Transaction t) {
    return [
      t.category.trim().toLowerCase(),
      (t.subcategory ?? '').trim().toLowerCase(),
      t.title.trim().toLowerCase(),
      t.amount.toString(),
      DateFormat('yyyy-MM-dd HH:mm').format(t.date),
    ].join('|');
  }

  static Data? _cell(List<Data?> row, int index) {
    return index < row.length ? row[index] : null;
  }

  static String _cellText(List<Data?> row, int index) {
    return _valueToText(_cell(row, index)?.value).trim();
  }

  static String _valueToText(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return DateFormat('yyyy-MM-dd')
          .format(DateTime(value.year, value.month, value.day));
    }
    if (value is DateTimeCellValue) {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime(
          value.year, value.month, value.day, value.hour, value.minute));
    }
    if (value is TimeCellValue) {
      return '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  static int? _cellAmount(List<Data?> row, int index) {
    final value = _cell(row, index)?.value;
    if (value == null) return null;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    final text = _valueToText(value).trim();
    if (text.isEmpty) return null;
    return int.tryParse(text) ?? double.tryParse(text)?.round();
  }

  static DateTime? _cellDateTime(
      List<Data?> row, int dateIndex, int timeIndex) {
    final dateValue = _cell(row, dateIndex)?.value;
    final timeValue = _cell(row, timeIndex)?.value;

    DateTime datePart;
    var hour = 0;
    var minute = 0;

    if (dateValue is DateCellValue) {
      datePart = DateTime(dateValue.year, dateValue.month, dateValue.day);
    } else if (dateValue is DateTimeCellValue) {
      datePart = DateTime(dateValue.year, dateValue.month, dateValue.day);
      hour = dateValue.hour;
      minute = dateValue.minute;
    } else {
      final text = _valueToText(dateValue).trim();
      if (text.isEmpty) return null;
      try {
        datePart = DateFormat('yyyy-MM-dd').parseStrict(text);
      } catch (_) {
        try {
          datePart = DateTime.parse(text);
        } catch (_) {
          return null;
        }
      }
    }

    if (timeValue is TimeCellValue) {
      hour = timeValue.hour;
      minute = timeValue.minute;
    } else if (timeValue is DateTimeCellValue) {
      hour = timeValue.hour;
      minute = timeValue.minute;
    } else {
      final text = _valueToText(timeValue).trim();
      if (text.isNotEmpty) {
        final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
        if (match != null) {
          hour = int.parse(match.group(1)!);
          minute = int.parse(match.group(2)!);
        }
      }
    }

    return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
  }
}
