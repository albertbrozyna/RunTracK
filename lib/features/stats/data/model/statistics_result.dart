class ChartDataPoint {
  final DateTime date;
  final double value;
  final String label;

  ChartDataPoint(this.date, this.value, this.label);
}

class StatisticsResult {
  final int totalActivities;
  final double totalDistanceKm;
  final Duration totalDuration;
  final double avgPace;
  final double bestPace;
  final double totalCalories;
  final double totalElevationGain;

  final List<ChartDataPoint> distancePerActivityData;
  final List<ChartDataPoint> cumulativeDistanceData;
  final List<ChartDataPoint> paceChartData;
  final List<ChartDataPoint> speedChartData;
  final List<ChartDataPoint> caloriesChartData;
  final List<ChartDataPoint> elevationChartData;

  final Map<String, int> activityTypeCounts;

  StatisticsResult({
    required this.totalActivities,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.avgPace,
    required this.bestPace,
    required this.totalCalories,
    required this.totalElevationGain,
    required this.distancePerActivityData,
    required this.cumulativeDistanceData,
    required this.paceChartData,
    required this.speedChartData,
    required this.caloriesChartData,
    required this.elevationChartData,
    required this.activityTypeCounts,
  });
}