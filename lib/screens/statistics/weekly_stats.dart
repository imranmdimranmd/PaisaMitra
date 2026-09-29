import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:paisa_mitra/models/transaction.dart';

class WeaklyStats extends StatefulWidget {
  final List<Transaction> rescentTransactions;

  WeaklyStats({
    Key? key,
    required this.rescentTransactions,
  }) : super(key: key);

  @override
  _WeaklyStatsState createState() => _WeaklyStatsState();
}

class _WeaklyStatsState extends State<WeaklyStats> {
  // final List<double> weeklyData = [5.0, 6.5, 5.0, 7.5, 9.0, 11.5, 6.5];

  int touchedIndex = -1;

  List<Map<String, Object>> get groupedTransactionValues {
    return List.generate(7, (index) {
      final weekDay = DateTime.now().subtract(
        Duration(days: index),
      );
      var totalSum = 0;
      for (var i = 0; i < widget.rescentTransactions.length; i++) {
        if (widget.rescentTransactions[i].date.day == weekDay.day &&
            widget.rescentTransactions[i].date.month == weekDay.month &&
            widget.rescentTransactions[i].date.year == weekDay.year) {
          totalSum += widget.rescentTransactions[i].amount;
        }
      }

      /*print(DateFormat.E().format(weekDay));
      print(totalSum);*/

      return {
        'date': DateFormat.d().format(weekDay), //.substring(0, 1),
        'amount': totalSum.toDouble(),
        'day': DateFormat.EEEE().format(weekDay),
      };
    }).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            color: Theme.of(context).primaryColorDark, //Color(0xff81e5cd),
          ),
          margin: EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                'Analysis',
                style: TextStyle(
                    color: Theme.of(context)
                        .primaryColorLight, //Color(0xff0f4a3c),
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Last Seven Days',
                style: TextStyle(
                    color: Theme.of(context)
                        .primaryColorLight, //const Color(0xff379982),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 25,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: BarChart(
                    mainBarData(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBar(
    int x,
    double y, {
    bool isTouched = false,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isTouched ? Theme.of(context).primaryColor : Colors.white,
          width: 22,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Theme.of(context).primaryColorLight,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildAllBars() {
    return List.generate(
      groupedTransactionValues.length,
      (index) => _buildBar(
          index, (groupedTransactionValues[index]['amount'] as num).toDouble(),
          isTouched: index == touchedIndex),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: _buildBarTouchData(),
      titlesData: _buildAxes(),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: _buildAllBars(),
    );
  }

  FlTitlesData _buildAxes() {
    return FlTitlesData(
      // Build X axis.
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
        ),
      ),
      // Build Y axis.
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        ),
      ),
    );
  }

  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      // touchTooltipData: BarTouchTooltipData(
      //   tooltipBgColor: Colors.blueGrey,
      //   getTooltipItem: (group, groupIndex, rod, rodIndex) {
      //     String weekDay;
      //     switch (group.x.toInt()) {
      //       case 0:
      //         weekDay = groupedTransactionValues[0]['day'];
      //         break;
      //       case 1:
      //         weekDay = groupedTransactionValues[1]['day'];
      //         break;
      //       case 2:
      //         weekDay = groupedTransactionValues[2]['day'];
      //         break;
      //       case 3:
      //         weekDay = groupedTransactionValues[3]['day'];
      //         break;
      //       case 4:
      //         weekDay = groupedTransactionValues[4]['day'];
      //         break;
      //       case 5:
      //         weekDay = groupedTransactionValues[5]['day'];
      //         break;
      //       case 6:
      //         weekDay = groupedTransactionValues[6]['day'];
      //         break;
      //     }
      //     return BarTooltipItem(
      //       weekDay + '\n' + (rod.y).toString(),
      //       TextStyle(color: Colors.yellow),
      //     );
      //   },
      // ),
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        setState(() {
          if (response != null) {
            touchedIndex = response.spot?.touchedBarGroupIndex ?? -1;
          } else {
            touchedIndex = -1;
          }
        });
      },
    );
  }
}
