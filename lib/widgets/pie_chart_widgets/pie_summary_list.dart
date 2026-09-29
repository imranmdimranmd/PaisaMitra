import 'package:flutter/material.dart';

import '../../models/pie_data.dart';

class PieSummaryList extends StatelessWidget {
  final List<PieData> pieData;

  const PieSummaryList({Key? key, required this.pieData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pieData.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = pieData[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(radius: 7, backgroundColor: item.color),
          title: Text(item.name),
          trailing: Text(
            '₹${item.price}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
