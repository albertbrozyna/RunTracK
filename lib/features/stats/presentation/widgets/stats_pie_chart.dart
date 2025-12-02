import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/widgets/no_items_msg.dart';

class StatsPieChart extends StatelessWidget {
  final Map<String, int> typeCounts;

  const StatsPieChart({super.key, required this.typeCounts});

  @override
  Widget build(BuildContext context) {
    if (typeCounts.isEmpty) {
      return SizedBox(
          width: double.infinity,
          child: const NoItemsMsg(textMessage: "No data"));
    }
    final colors = [Colors.blue, Colors.redAccent, Colors.green, Colors.orange, Colors.purpleAccent];
    int i = 0;

    return Container(
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)
        ),
        child: Padding(
            padding: EdgeInsets.all(20.0),
            child: SizedBox(
      height:300,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: typeCounts.entries.map((e) {
                  final color = colors[i++ % colors.length];
                  final total = typeCounts.values.reduce((a, b) => a + b);
                  final percent = (e.value / total * 100).toStringAsFixed(0);

                  return PieChartSectionData(
                    color: color,
                    value: e.value.toDouble(),
                    title: "$percent%",
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: typeCounts.entries.map((e) {
              int index = typeCounts.keys.toList().indexOf(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: colors[index % colors.length]),
                    const SizedBox(width: 8),
                    Text("${e.key} (${e.value})"),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
            ),
        ));
  }
}