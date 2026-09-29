import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:paisa_mitra/models/pie_data.dart';
import 'package:paisa_mitra/models/transaction.dart';
import 'package:paisa_mitra/screens/statistics/pie_chart.dart';
import 'package:paisa_mitra/screens/statistics/weekly_stats.dart';
import 'package:paisa_mitra/widgets/no_trancaction.dart';
import 'package:paisa_mitra/widgets/grouped_transaction_list.dart';

class WeeklySpendings extends StatefulWidget {
  @override
  _WeeklySpendingsState createState() => _WeeklySpendingsState();
}

class _WeeklySpendingsState extends State<WeeklySpendings> {
  bool _showChart = false;
  bool _byCategory = true;
  late Transactions trxData;
  // List<Transaction> recentTransaction;
  // List<PieData> recentData;
  // Function deleteFn;

  @override
  void initState() {
    super.initState();

    trxData = Provider.of<Transactions>(context, listen: false);
    // recentTransaction =
    //     Provider.of<Transactions>(context, listen: false).rescentTransactions;

    // deleteFn =
    //     Provider.of<Transactions>(context, listen: false).deleteTransaction;

    // recentData = PieData().pieChartData(recentTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final deleteFn = Provider.of<Transactions>(context).deleteTransaction;
    final recentTransaction =
        Provider.of<Transactions>(context, listen: false).rescentTransactions;
    final recentData = PieData.pieChartData(recentTransaction, byCategory: _byCategory);
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
              padding: const EdgeInsets.only(
                  right: 15, top: 10, bottom: 10, left: 15),
              color: Theme.of(context).primaryColorLight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "₹${trxData.getTotal(recentTransaction)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Show Chart',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Switch.adaptive(
                        activeColor: Theme.of(context).colorScheme.secondary,
                        value: _showChart,
                        onChanged: (val) {
                          setState(() {
                            _showChart = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showChart)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Category')),
                          ButtonSegment(value: false, label: Text('Subcategory')),
                        ],
                        selected: {_byCategory},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _byCategory = selection.first;
                          });
                        },
                      ),
                    ),
                ],
              )),
          recentTransaction.isEmpty
              ? NoTransactions()
              : (_showChart
                  ? weaklyChart(
                      context, recentTransaction, recentData, _byCategory)
                  : GroupedTransactionList(
                      transactions: recentTransaction,
                      dltTrxItem: deleteFn,
                    ))
        ],
      ),
    );
  }

  Column weaklyChart(
    BuildContext context,
    List<Transaction> recentTransaction,
    List<PieData> recentData,
    bool byCategory,
  ) {
    return Column(
      children: [
        Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          color: Theme.of(context).primaryColorDark,
          child: MyPieChart(
            pieData: recentData,
            sourceTransactions: recentTransaction,
            byCategory: byCategory,
          ),
        ),
        WeaklyStats(
          rescentTransactions: recentTransaction,
        )
      ],
    );
  }
}
