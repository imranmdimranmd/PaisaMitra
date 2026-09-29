import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../DBhelp/dbhelper.dart';
import '../models/categories.dart';
import '../models/transaction.dart';

class BudgetsScreen extends StatefulWidget {
  static const routeName = '/budgets';

  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<Map<String, dynamic>>> _budgets;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _budgets = DBHelper.fetchBudgets(_month.month, _month.year);
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _reload();
    });
  }

  Future<void> _editBudget({Map<String, dynamic>? existing}) async {
    final categories = context.read<Categories>();
    String category = existing?['category'] as String? ?? categories.categories.first;
    String? subcategory = existing?['subcategory'] as String?;
    final amountController = TextEditingController(
        text: existing == null ? '' : '${existing['amount']}');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final subs = categories.subcategoriesFor(category);
          if (subcategory != null && !subs.contains(subcategory)) subcategory = null;
          return AlertDialog(
            title: Text(existing == null ? 'Add budget' : 'Edit budget'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.categories
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setDialogState(() {
                    category = value!;
                    subcategory = null;
                  }),
                ),
                DropdownButtonFormField<String?>(
                  value: subcategory,
                  decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Whole category')),
                    ...subs.map((item) => DropdownMenuItem<String?>(value: item, child: Text(item))),
                  ],
                  onChanged: (value) => setDialogState(() => subcategory = value),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monthly amount'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final amount = int.tryParse(amountController.text);
                  if (amount == null || amount < 0) return;
                  await DBHelper.saveBudget(
                    category: category,
                    subcategory: subcategory,
                    month: _month.month,
                    year: _month.year,
                    amount: amount,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) setState(_reload);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly budgets'),
        actions: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(DateFormat.yMMMM().format(_month), style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _budgets,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No budgets for this month'));
                }

                return Consumer<Transactions>(
                  builder: (context, transactionProvider, _) {
                    final monthTransactions = transactionProvider.transactions
                        .where((t) =>
                            !t.isIncome &&
                            t.date.month == _month.month &&
                            t.date.year == _month.year)
                        .toList();

                    int spentFor(Map<String, dynamic> budget) {
                      final category = budget['category'] as String;
                      final subcategory = budget['subcategory'] as String?;
                      return monthTransactions
                          .where((t) =>
                              t.category == category &&
                              (subcategory == null ||
                                  t.subcategory?.trim() == subcategory))
                          .fold<int>(0, (sum, t) => sum + t.amount);
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final label = item['subcategory'] == null
                            ? item['category'] as String
                            : '${item['category']} / ${item['subcategory']}';
                        final budgetAmount = item['amount'] as int;
                        final spent = spentFor(item);
                        final exceeded = spent > budgetAmount;
                        final titleColor = exceeded ? Colors.red : null;

                        return ListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: exceeded ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(
                            'Budget: ₹$budgetAmount  •  Spent: ₹$spent',
                            style: TextStyle(color: exceeded ? Colors.red : null),
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete budget',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await DBHelper.deleteBudget(item['id'] as int);
                              setState(_reload);
                            },
                          ),
                          onTap: () => _editBudget(existing: item),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final categories = context.read<Categories>().categories;
          if (categories.isNotEmpty) _editBudget();
        },
        tooltip: 'Add budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}
