import 'package:paisa_mitra/models/pie_data.dart';
import 'package:flutter/material.dart';

class IndicatorsWidget extends StatelessWidget {
  final List<PieData> pieData;

  /// Called with the tapped item's index when the legend entry for that
  /// slice is tapped. Legend entries are not tappable when this is null.
  final void Function(int index)? onTap;

  const IndicatorsWidget({
    Key? key,
    required this.pieData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: pieData
            .asMap()
            .entries
            .map(
              (entry) => InkWell(
                onTap: onTap == null ? null : () => onTap!(entry.key),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 4),
                  child: buildIndicator(
                    color: entry.value.color,
                    text: entry.value.name,
                    amount: entry.value.price,
                  ),
                ),
              ),
            )
            .toList(),
      );

  Widget buildIndicator({
    required Color color,
    required String text,
    required int amount,
    double size = 16,
    Color textColor = const Color(0xff000000),
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹$amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
          ],
        ],
      );
}
