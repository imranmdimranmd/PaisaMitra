import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import 'new_transaction.dart';

class IncomeScreen extends StatelessWidget {
  static const routeName = '/income';

  const IncomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: Consumer<Transactions>(
        builder: (context, transactions, child) {
          final now = DateTime.now();
          final income = transactions.transactions.where((item) {
            return item.isIncome && item.date.year == now.year && item.date.month == now.month;
          }).toList();
          final total = transactions.getTotalIncome(income);
          return Column(
            children: [
              ListTile(
                title: Text(DateFormat.yMMMM().format(now)),
                trailing: Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const Divider(height: 1),
              Expanded(
                child: income.isEmpty
                    ? const Center(child: Text('No income recorded this month'))
                    : ListView.builder(
                        itemCount: income.length,
                        itemBuilder: (context, index) {
                          final item = income[index];
                          return ListTile(
                            leading: const Icon(Icons.arrow_downward, color: Colors.green),
                            title: Text(item.title),
                            subtitle: Text(DateFormat.yMMMd().format(item.date)),
                            trailing: Text('₹${item.amount}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewTransaction(initialIsIncome: true)),
        ),
        tooltip: 'Add income',
        child: const Icon(Icons.add),
      ),
    );
  }
}
