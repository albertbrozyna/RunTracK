import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/widgets/no_items_msg.dart';
import 'package:run_track/features/stats/data/model/statistics_result.dart';

class StatsLineChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final Color color;
  final String unit;
  final bool isFilled;
  final bool isPace;

  const StatsLineChart({
    super.key,
    required this.data,
    required this.color,
    required this.unit,
    this.isFilled = false,
    this.isPace = false,
  });

  String _formatPace(double value) {
    int minutes = value.floor();
    int seconds = ((value - minutes) * 60).round();
    if (seconds == 60) {
      minutes++;
      seconds = 0;
    }
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: const NoItemsMsg(textMessage: "No data"),
      );
    }

    double maxY = data.map((e) => e.value).reduce(max);
    double minY = data.map((e) => e.value).reduce(min);

    // Calculating interval
    double interval = maxY > 0 ? maxY / 4 : 1.0;

    // For pace add a 0.5 min diff
    if (isPace && maxY - minY < 1) {
      interval = 0.5;
    }
    if (interval == 0) {
      interval = 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
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
                      if (value <= 0) {
                        return const SizedBox();
                      }

                      String text;

                      if (isPace) {
                        text = _formatPace(value);
                      } else {
                        if (value % 1 == 0) {
                          text = value.toInt().toString();
                        } else {
                          if (value < 10) {
                            text = value.toStringAsFixed(2);
                          } else {
                            text = value.toStringAsFixed(1);
                          }
                        }
                        if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
                        if (text.endsWith('.00')) text = text.substring(0, text.length - 3);
                      }

                      return Text(
                        "$text $unit",
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

              minY: isPace ? (minY * 0.9) : 0,
              maxY: maxY * 1.1,

              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < data.length) {
                        final point = data[index];

                        String valStr;
                        if (isPace) {
                          valStr = _formatPace(point.value);
                        } else {
                          valStr = point.value.toStringAsFixed(2);
                          if (valStr.endsWith('0')) valStr = valStr.substring(0, valStr.length - 1);
                          if (valStr.endsWith('.0')) {
                            valStr = valStr.substring(0, valStr.length - 2);
                          }
                        }

                        return LineTooltipItem(
                          "${DateFormat('dd.MM').format(point.date)}\n$valStr $unit",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                      .toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: isFilled, color: color.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
