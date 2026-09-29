import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import 'transaction_list_items.dart';

/// Groups transactions by calendar day (newest day first, matching the
/// existing newest-first ordering) and shows a running total per day —
/// similar to Bluecoins' date-grouped transaction reports with running
/// balances.
class GroupedTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function dltTrxItem;

  const GroupedTransactionList({
    Key? key,
    required this.transactions,
    required this.dltTrxItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    for (final trx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(trx.date);
      groups.putIfAbsent(key, () => []).add(trx);
    }

    // Running total counted from the oldest transaction through each day,
    // shown newest-day-first (so it decreases as you scroll to older days).
    var runningTotal = transactions.fold<int>(0, (sum, t) => sum + t.amount);

    final widgets = <Widget>[];
    for (final dayTransactions in groups.values) {
      final dayTotal =
          dayTransactions.fold<int>(0, (sum, t) => sum + t.amount);

      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy')
                  .format(dayTransactions.first.date),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '₹$dayTotal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ));

      for (final trx in dayTransactions) {
        widgets.add(TransactionListItems(trx: trx, dltTrxItem: dltTrxItem));
      }

      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Running total: ₹$runningTotal',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ));

      runningTotal -= dayTotal;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
