import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:paisa_mitra/models/pie_data.dart';
import 'package:paisa_mitra/models/transaction.dart';
import 'package:paisa_mitra/screens/statistics/pie_chart.dart';
import 'package:paisa_mitra/widgets/no_trancaction.dart';
import 'package:paisa_mitra/widgets/grouped_transaction_list.dart';

class DailySpendings extends StatefulWidget {
  @override
  _DailySpendingsState createState() => _DailySpendingsState();
}

class _DailySpendingsState extends State<DailySpendings> {
  bool _showChart = false;
  bool _byCategory = true;
  late Transactions trxData;
  late Function deleteFn;

  @override
  void initState() {
    super.initState();
    trxData = Provider.of<Transactions>(context, listen: false);

    deleteFn =
        Provider.of<Transactions>(context, listen: false).deleteTransaction;
  }

  @override
  Widget build(BuildContext context) {
    final dailyTrans = Provider.of<Transactions>(context).dailyTransactions();

    final List<PieData> dailyData =
        PieData.pieChartData(dailyTrans, byCategory: _byCategory);

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
                        "₹${trxData.getTotal(dailyTrans)}",
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
          dailyTrans.isEmpty
              ? NoTransactions()
              : (_showChart
                  ? Column(
                      children: [
                        MyPieChart(
                            pieData: dailyData,
                            sourceTransactions: dailyTrans,
                            byCategory: _byCategory),
                      ],
                    )
                  : GroupedTransactionList(
                      transactions: dailyTrans, dltTrxItem: deleteFn))
        ],
      ),
    );
  }
}
