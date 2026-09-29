import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

/// Bluecoins-style dashboard summary cards shown at the top of the Home
/// screen: today's spend, this month's spend, and the top category so far
/// this month.
class DashboardSummaryCards extends StatelessWidget {
  final Transactions transactions;

  const DashboardSummaryCards({Key? key, required this.transactions})
      : super(key: key);

  String _topCategory(List<Transaction> trx) {
    if (trx.isEmpty) return '—';
    final totals = <String, int>{};
    for (final t in trx) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayTotal = transactions.getTotal(transactions.dailyTransactions());
    final monthTrx = transactions.monthlyTransactions(
      DateFormat('MMM').format(now),
      DateFormat('yyyy').format(now),
    );
    final monthTotal = transactions.getTotal(monthTrx);
    final topCategory = _topCategory(monthTrx);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _card(context, 'Today', '₹$todayTotal', Icons.today),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _card(context, 'This Month', '₹$monthTotal',
                Icons.calendar_month),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _card(
                context, 'Top Category', topCategory, Icons.pie_chart),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _card(
              context,
              'Income',
              '₹${transactions.getTotalIncome(transactions.transactions)}',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
