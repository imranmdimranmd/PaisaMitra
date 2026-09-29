import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:paisa_mitra/models/transaction.dart';
import 'package:paisa_mitra/widgets/grouped_transaction_list.dart';
import 'package:paisa_mitra/widgets/no_trancaction.dart';

/// Shown when the user taps a slice (or legend entry) of a spending pie
/// chart. Lists every transaction that makes up that slice, so a category
/// or subcategory total can be inspected transaction-by-transaction.
class CategoryTransactionsScreen extends StatelessWidget {
  static const routeName = '/category-transactions';

  final String title;
  final List<Transaction> transactions;

  const CategoryTransactionsScreen({
    Key? key,
    required this.title,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Re-derive the list from the live provider (matched by id) instead of
    // holding on to the snapshot passed at navigation time, so deleting a
    // transaction here (or renaming its category elsewhere) is reflected
    // immediately without needing to back out and re-open the chart.
    final ids = transactions.map((t) => t.id).toSet();
    final trxProvider = context.watch<Transactions>();
    final liveTransactions =
        trxProvider.transactions.where((t) => ids.contains(t.id)).toList();

    final total = liveTransactions.fold<int>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColorLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${liveTransactions.length} transaction'
                    '${liveTransactions.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            liveTransactions.isEmpty
                ? const NoTransactions()
                : GroupedTransactionList(
                    transactions: liveTransactions,
                    dltTrxItem: trxProvider.deleteTransaction,
                  ),
          ],
        ),
      ),
    );
  }
}
