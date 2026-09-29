import 'package:flutter/material.dart';

import 'package:paisa_mitra/models/pie_data.dart';
import 'package:paisa_mitra/models/transaction.dart';
import 'package:paisa_mitra/screens/statistics/pie_chart.dart';
import 'package:paisa_mitra/widgets/no_trancaction.dart';
import 'package:paisa_mitra/widgets/grouped_transaction_list.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlySpendings extends StatefulWidget {
  @override
  _MonthlySpendingsState createState() => _MonthlySpendingsState();
}

class _MonthlySpendingsState extends State<MonthlySpendings> {
  String _selectedYear = DateFormat('yyyy').format(DateTime.now());
  String dropdownValue = DateFormat('MMM').format(DateTime.now());

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
    final monthlyTrans = Provider.of<Transactions>(context)
        .monthlyTransactions(dropdownValue, _selectedYear);
    final List<PieData> monthlyData =
        PieData.pieChartData(monthlyTrans, byCategory: _byCategory);

    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding:
                const EdgeInsets.only(right: 10, left: 5, top: 5, bottom: 5),
            color: Theme.of(context).primaryColorLight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    dropDownToSelectMonth(context),
                    widgetToSelectYear(),
                    Text(
                      "₹${trxData.getTotal(monthlyTrans)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
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
            ),
          ),
          monthlyTrans.isEmpty
              ? NoTransactions()
              : (_showChart
                  ? Column(
                      children: [
                        MyPieChart(
                            pieData: monthlyData,
                            sourceTransactions: monthlyTrans,
                            byCategory: _byCategory),
                      ],
                    )
                  : GroupedTransactionList(
                      transactions: monthlyTrans, dltTrxItem: deleteFn)),
        ],
      ),
    );
  }

  Row widgetToSelectYear() {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: int.parse(_selectedYear) == 0
              ? null
              : () {
                  setState(() {
                    _selectedYear = (int.parse(_selectedYear) - 1).toString();
                  });
                },
        ),
        Text(_selectedYear),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: _selectedYear == DateFormat('yyyy').format(DateTime.now())
              ? null
              : () {
                  setState(() {
                    _selectedYear = (int.parse(_selectedYear) + 1).toString();
                  });
                },
        ),
      ],
    );
  }

  DropdownButton<String> dropDownToSelectMonth(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(
        Icons.expand_more,
      ),
      elevation: 16,
      style: TextStyle(color: Theme.of(context).primaryColorDark),
      underline: Container(
        height: 2,
        color: Theme.of(context).primaryColor,
      ),
      onChanged: (String? newValue) {
        setState(() {
          dropdownValue = newValue ?? DateFormat('MMM').format(DateTime.now());
        });
      },
      items: <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
