import 'package:flutter/material.dart';
import 'package:run_track/core/widgets/stat_card.dart';
import 'package:run_track/features/stats/data/model/statistics_result.dart';

class StatsSummaryGrid extends StatelessWidget {
  final StatisticsResult stats;
  final double _statCardHeight = 60.0;
  const StatsSummaryGrid({super.key, required this.stats});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      StatCard(
        title: "Activities",
        value: "${stats.totalActivities}",
        icon: Icon(Icons.directions_run),
        cardHeight: _statCardHeight,
      ),
      StatCard(
        title: "Distance",
        value: "${stats.totalDistanceKm.toStringAsFixed(2)} km",
        icon: Icon(Icons.map),
        cardHeight: _statCardHeight,

      ),
      StatCard(title: "Time", value: _formatDuration(stats.totalDuration), icon: Icon(Icons.timer)),
      StatCard(
        title: "Calories",
        value: "${stats.totalCalories.toInt()} kcal",
        icon: Icon(Icons.local_fire_department),
        cardHeight: _statCardHeight,

      ),
      StatCard(
        title: "Avg. Pace",
        value: '${stats.avgPace.toStringAsFixed(2)} min/km',
        icon: Icon(Icons.speed),
        cardHeight: _statCardHeight,

      ),
      StatCard(
        title: "Best Pace",
        value: '${stats.bestPace.toStringAsFixed(2)} min/km',
        icon: Icon(Icons.bolt),
        cardHeight: _statCardHeight,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: items,
    );
  }
}
