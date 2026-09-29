import 'package:flutter/material.dart';

import 'package:random_color/random_color.dart';

import 'package:paisa_mitra/models/transaction.dart';

class PieData {
  final String name;
  final double percent;
  final Color color;
  final int price;

  const PieData({
    required this.name,
    required this.percent,
    required this.color,
    required this.price,
  });

  static List<PieData> pieChartData(List<Transaction> trx,
      {bool byCategory = true}) {
    int total = Transactions().getTotal(trx);
    if (total == 0) return [];
    List<Map<String, Object>> finalData = sortedPieData(trx, byCategory: byCategory);
    RandomColor _randomColor = RandomColor();

    List<PieData> data = [];

    finalData.forEach((element) {
      Color _color =
          _randomColor.randomColor(colorBrightness: ColorBrightness.primary);
      data.add(
        PieData(
          name: element['title'] as String,
          percent: (((element['amount'] as int) * 100) / total)
              .round()
              .ceilToDouble(),
          color: _color,
          price: element['amount'] as int,
        ),
      );
    });

    return data;
  }

  // Sorting data category-wise or subcategory-wise.
  static List<Map<String, Object>> sortedPieData(List<Transaction> trx,
      {bool byCategory = true}) {
    List<Map<String, Object>> finalList = [];

    for (var i = 0; i < trx.length; i++) {
      final key = byCategory
          ? trx[i].category
          : (trx[i].subcategory?.trim().isNotEmpty == true
              ? trx[i].subcategory!
              : 'Unspecified');

      var index = finalList.indexWhere((element) => element['title'] == key);

      if (index != -1) {
        finalList[index]['amount'] =
            (finalList[index]['amount'] as int) + trx[i].amount;
      } else {
        finalList.add({
          'title': key,
          'amount': trx[i].amount,
        });
      }
    }
    return finalList;
  }
}
