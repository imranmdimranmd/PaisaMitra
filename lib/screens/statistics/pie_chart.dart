import 'package:paisa_mitra/models/pie_data.dart';
import 'package:paisa_mitra/models/transaction.dart';
import 'package:paisa_mitra/screens/transactions/category_transactions_screen.dart';
import 'package:paisa_mitra/widgets/pie_chart_widgets/pie_chart_sections.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyPieChart extends StatefulWidget {
  final List<PieData> pieData;

  /// The transactions the [pieData] slices were built from, and whether
  /// they were grouped by category or subcategory. When both are supplied,
  /// Tapping a slice opens the list of transactions that make up that slice.
  final List<Transaction>? sourceTransactions;
  final bool byCategory;

  const MyPieChart({
    Key? key,
    required this.pieData,
    this.sourceTransactions,
    this.byCategory = true,
  }) : super(key: key);

  @override
  _MyPieChartState createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  int touchedIndex = -1;

  void _openTransactionsFor(int index) {
    final source = widget.sourceTransactions;
    if (source == null || index < 0 || index >= widget.pieData.length) return;

    final sliceName = widget.pieData[index].name;
    final filtered = source.where((trx) {
      if (widget.byCategory) {
        return trx.category == sliceName;
      }
      final subcategory = (trx.subcategory?.trim().isNotEmpty == true)
          ? trx.subcategory!
          : 'Unspecified';
      return subcategory == sliceName;
    }).toList();

    _openTransactionList(sliceName, filtered);
  }

  void _openTransactionList(String title, List<Transaction> transactions) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryTransactionsScreen(
          title: title,
          transactions: transactions,
        ),
      ),
    );
  }

  Map<String, List<Transaction>> _transactionsBy(
    Iterable<Transaction> transactions,
    String Function(Transaction transaction) keyFor,
  ) {
    final grouped = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final key = keyFor(transaction);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return grouped;
  }

  int _total(List<Transaction> transactions) =>
      transactions.fold(0, (sum, transaction) => sum + transaction.amount);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canDrillDown = widget.sourceTransactions != null;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          if (canDrillDown && widget.pieData.isNotEmpty)
            Card(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Categories / Subcategories',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ...widget.pieData.map((item) {
                    final transactions = widget.sourceTransactions!.where((trx) {
                      if (widget.byCategory) return trx.category == item.name;
                      final sub = trx.subcategory?.trim().isNotEmpty == true
                          ? trx.subcategory!
                          : 'Unspecified';
                      return sub == item.name;
                    }).toList();

                    return InkWell(
                      onTap: () => _openTransactionList(item.name, transactions),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: item.color,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${item.percent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${item.price}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.open_in_new, size: 17),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          SizedBox(
            height: 360,
            child: GestureDetector(
              onTap: canDrillDown && touchedIndex != -1
                  ? () => _openTransactionsFor(touchedIndex)
                  : null,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event,
                        PieTouchResponse? response) {
                      setState(() {
                        touchedIndex = response?.touchedSection
                                ?.touchedSectionIndex ??
                            -1;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections:
                      getSections(touchedIndex, widget.pieData, screenWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
