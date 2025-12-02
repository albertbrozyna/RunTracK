import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/widgets/no_items_msg.dart';
import 'package:run_track/features/stats/data/model/statistics_result.dart';

class StatsBarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final Color color;
  final String unit;

  const StatsBarChart({
    super.key,
    required this.data,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: const NoItemsMsg(textMessage: "No data"),
      );
    }

    double maxY = data.map((e) => e.value).reduce(max);
    double interval = maxY > 0 ? maxY / 5 : 1.0;
    if (interval == 0) interval = 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 65,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0) return const SizedBox();

                      return Text(
                        "${value.toInt()} $unit",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              maxY: maxY * 1.2,

              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = data[group.x.toInt()];
                    return BarTooltipItem(
                      "${DateFormat('dd.MM').format(point.date)}\n${point.value.toInt()} $unit",
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: color,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}