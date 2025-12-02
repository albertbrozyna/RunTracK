import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_track/core/constants/firestore_collections.dart';
import 'package:run_track/core/models/activity.dart';
import 'package:run_track/features/stats/data/model/statistics_result.dart';

class ActivityStatisticsService {
  ActivityStatisticsService.privateConst();
  static final ActivityStatisticsService instance = ActivityStatisticsService.privateConst();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StatisticsResult> getUserStatistics({
    required String uid,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      // Fetch activities from start date to end date
      final QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.activities)
          .where('uid', isEqualTo: uid)
          .where('startTime', isGreaterThanOrEqualTo: fromDate)
          .where('startTime', isLessThanOrEqualTo: toDate)
          .orderBy('startTime', descending: false)
          .get();

      final List<Activity> activities = snapshot.docs
          .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      double totalDist = 0; // in meters
      int totalSeconds = 0;
      double totalCals = 0;
      double totalElevGain = 0;

      double sumPace = 0;
      int paceCount = 0;
      double bestPace = double.infinity;

      double runningTotalDistance = 0;
      Map<String, int> typeCounts = {};

      // Charts
      List<ChartDataPoint> distPoints = [];
      List<ChartDataPoint> cumulativePoints = [];
      List<ChartDataPoint> pacePoints = [];
      List<ChartDataPoint> speedPoints = [];
      List<ChartDataPoint> calPoints = [];
      List<ChartDataPoint> elevPoints = [];

      for (var activity in activities) {
        final double dist = activity.totalDistance ?? 0;
        final int time = activity.elapsedTime ?? 0;
        final double cals = activity.calories ?? 0;
        final double elev = activity.elevationGain ?? 0;

        final DateTime date = activity.startTime ?? DateTime.now();
        final String label = activity.title ?? "Activity";

        totalDist += dist;
        totalSeconds += time;
        totalCals += cals;
        totalElevGain += elev;
        runningTotalDistance += dist;

        if (activity.pace != null && activity.pace! > 0) {
          sumPace += activity.pace!;
          paceCount++;
          if (activity.pace! < bestPace) {
            bestPace = activity.pace!;
          }
          pacePoints.add(ChartDataPoint(date, activity.pace!, label));
        }

        String type = activity.activityType ?? "Other";
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;

        // Distance to km
        distPoints.add(ChartDataPoint(date, dist / 1000, label));
        cumulativePoints.add(ChartDataPoint(date, runningTotalDistance / 1000, label));
        speedPoints.add(ChartDataPoint(date, activity.avgSpeed ?? 0, label));

        if (cals > 0) calPoints.add(ChartDataPoint(date, cals, label));
        if (elev > 0) elevPoints.add(ChartDataPoint(date, elev, label));
      }

      final double avgPaceCalc = paceCount > 0 ? sumPace / paceCount : 0;
      final double finalBestPace = bestPace == double.infinity ? 0 : bestPace;

      totalDist /= 1000;  // Convert to km

      return StatisticsResult(
        totalActivities: activities.length,
        totalDistanceKm: totalDist,
        totalDuration: Duration(seconds: totalSeconds),
        avgPace: avgPaceCalc,
        bestPace: finalBestPace,
        totalCalories: totalCals,
        totalElevationGain: totalElevGain,
        distancePerActivityData: distPoints,
        cumulativeDistanceData: cumulativePoints,
        paceChartData: pacePoints,
        speedChartData: speedPoints,
        caloriesChartData: calPoints,
        elevationChartData: elevPoints,
        activityTypeCounts: typeCounts,
      );

    } catch (e) {
      return StatisticsResult(
        totalActivities: 0, totalDistanceKm: 0, totalDuration: Duration.zero,
        avgPace: 0, bestPace: 0, totalCalories: 0, totalElevationGain: 0,
        distancePerActivityData: [], cumulativeDistanceData: [], paceChartData: [],
        speedChartData: [], caloriesChartData: [], elevationChartData: [],
        activityTypeCounts: {},
      );
    }
  }
}