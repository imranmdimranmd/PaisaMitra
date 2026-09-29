import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';

class ExportService {
  /// Builds an .xlsx workbook from the given transactions (Category >
  /// Subcategory > Item hierarchy) and opens the platform share sheet so the
  /// user can save or send the file.
  static Future<void> exportTransactionsToExcel(
      List<Transaction> transactions) async {
    final workbook = Excel.createExcel();
    final defaultSheetName = workbook.getDefaultSheet();

    final detailSheet = workbook['Transactions'];
    detailSheet.appendRow([
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Subcategory'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Name'),
      TextCellValue('Amount'),
    ]);

    final sorted = [...transactions]
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final trx in sorted) {
      detailSheet.appendRow([
        TextCellValue('Expense'),
        TextCellValue(trx.category),
        TextCellValue(trx.subcategory ?? ''),
        TextCellValue(DateFormat('yyyy-MM-dd').format(trx.date)),
        TextCellValue(DateFormat('HH:mm').format(trx.date)),
        TextCellValue(trx.title),
        IntCellValue(trx.amount),
      ]);
    }

    final summarySheet = workbook['Summary by Category'];
    summarySheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Total Amount'),
    ]);
    final totalsByCategory = <String, int>{};
    for (final trx in transactions) {
      totalsByCategory[trx.category] =
          (totalsByCategory[trx.category] ?? 0) + trx.amount;
    }
    for (final entry in totalsByCategory.entries) {
      summarySheet.appendRow([
        TextCellValue(entry.key),
        IntCellValue(entry.value),
      ]);
    }

    if (defaultSheetName != null && defaultSheetName != 'Transactions') {
      workbook.delete(defaultSheetName);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'PaisaMitra_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Paisa Mitra expense export',
    );
  }
}
