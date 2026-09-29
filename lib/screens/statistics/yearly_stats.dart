import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

class YearlyStats extends StatefulWidget {
  final List<Map<String, Object>> groupedTransactionValues;

  const YearlyStats({
    Key? key,
    required this.groupedTransactionValues,
  }) : super(key: key);

  @override
  _YearlyStatsState createState() => _YearlyStatsState();
}

class _YearlyStatsState extends State<YearlyStats> {
  // final List<double> weeklyData = [5.0, 6.5, 5.0, 7.5, 9.0, 11.5, 6.5];

  int touchedIndex = -1;

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
                'Monthly Analysis',
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
      widget.groupedTransactionValues.length,
      (index) => _buildBar(index,
          (widget.groupedTransactionValues[index]['amount'] as num).toDouble(),
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
      //         weekDay = widget.groupedTransactionValues[0]['month'];
      //         break;
      //       case 1:
      //         weekDay = widget.groupedTransactionValues[1]['month'];
      //         break;
      //       case 2:
      //         weekDay = widget.groupedTransactionValues[2]['month'];
      //         break;
      //       case 3:
      //         weekDay = widget.groupedTransactionValues[3]['month'];
      //         break;
      //       case 4:
      //         weekDay = widget.groupedTransactionValues[4]['month'];
      //         break;
      //       case 5:
      //         weekDay = widget.groupedTransactionValues[5]['month'];
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
