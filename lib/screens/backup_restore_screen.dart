import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/categories.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

/// Bluecoins-style "Backup & Restore" screen: a single place to export all
/// transactions to an Excel file, or import transactions from one.
class BackupRestoreScreen extends StatefulWidget {
  static const routeName = '/backup-restore';

  const BackupRestoreScreen({Key? key}) : super(key: key);

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isWorking = false;

  Future<void> _export() async {
    final transactions =
        Provider.of<Transactions>(context, listen: false).transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    setState(() => _isWorking = true);
    try {
      await ExportService.exportTransactionsToExcel(transactions);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _isWorking = true);
    try {
      final transactionsProvider =
          Provider.of<Transactions>(context, listen: false);
      final categoriesProvider =
          Provider.of<Categories>(context, listen: false);
      final summary = await ImportService.importTransactionsFromExcel(
        path,
        transactionsProvider.transactions,
      );
      await transactionsProvider.fetchTransactions();
      await categoriesProvider.load();

      if (!mounted) return;
      final messageParts = <String>[
        'Imported ${summary.imported}',
        'skipped ${summary.duplicatesSkipped} duplicate(s)',
      ];
      if (summary.invalidRowsSkipped > 0) {
        messageParts.add('${summary.invalidRowsSkipped} invalid row(s)');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageParts.join(', '))),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: AbsorbPointer(
        absorbing: _isWorking,
        child: Opacity(
          opacity: _isWorking ? 0.6 : 1,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'BACKUP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Export transactions'),
                subtitle: const Text(
                  'Save all transactions to an Excel (.xlsx) file and share it',
                ),
                onTap: _export,
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'RESTORE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import transactions'),
                subtitle: const Text(
                  'Load transactions from an Excel file exported by this app. '
                  'Rows that duplicate an existing transaction across all '
                  'columns are skipped automatically.',
                ),
                onTap: _import,
              ),
              const Divider(height: 1),
              if (_isWorking)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
