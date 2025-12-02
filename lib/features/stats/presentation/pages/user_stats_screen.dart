import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';
import 'package:run_track/core/widgets/no_items_msg.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/stats/data/model/statistics_result.dart';
import 'package:run_track/features/stats/data/service/statistics_service.dart';
import 'package:run_track/features/stats/presentation/widgets/stats_bar_chart.dart';
import 'package:run_track/features/stats/presentation/widgets/stats_line_chart.dart';
import 'package:run_track/features/stats/presentation/widgets/stats_summary_grid.dart';

import '../widgets/stats_pie_chart.dart';

class UserStatsScreen extends StatefulWidget {
  final String uid;

  const UserStatsScreen({super.key, required this.uid});

  @override
  State<StatefulWidget> createState() => UserStatsScreenState();
}

class UserStatsScreenState extends State<UserStatsScreen> {
  late Future<StatisticsResult> _statsFuture;
  final ActivityStatisticsService _service = ActivityStatisticsService.instance;

  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    initialize();
    _loadStats();
  }

  void initialize() {
    final now = DateTime.now();
    _fromDate = now.subtract(const Duration(days: 30));
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Pick start and end date
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        // Set end of the day
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _loadStats();
      });
    }
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _service.getUserStatistics(
        uid: widget.uid,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String dateRangeText =
        "${DateFormat('dd.MM.yyyy').format(_fromDate)}  -  ${DateFormat('dd.MM.yyyy').format(_toDate)}";
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: PageContainer(
        assetPath: AppImages.appBg4,
        darken: true,
        child: FutureBuilder<StatisticsResult>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(child: NoItemsMsg(textMessage: "Error: ${snapshot.error}"));
            }

            final stats = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_calendar, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              dateRangeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (stats.totalActivities == 0)
                    const Center(
                      child: NoItemsMsg(textMessage: "No activities in the selected period."),
                    )
                  else ...[
                    StatsSummaryGrid(stats: stats),

                    const SizedBox(height: 30),

                    _buildHeader("Cumulative Distance (Progress)"),
                    StatsLineChart(
                      data: stats.cumulativeDistanceData,
                      color: Colors.blueAccent,
                      unit: "km",
                      isFilled: true,
                    ),

                    const SizedBox(height: 24),

                    _buildHeader("Calories Burned"),
                    StatsBarChart(
                      data: stats.caloriesChartData,
                      color: Colors.orange,
                      unit: "kcal",
                    ),

                    const SizedBox(height: 24),

                    _buildHeader("Average Pace (min/km)"),
                    StatsLineChart(
                      data: stats.paceChartData,
                      color: Colors.purple,
                      unit: "min/km",
                      isPace: true,
                    ),

                    const SizedBox(height: 24),

                    _buildHeader("Elevation Gain"),
                    StatsLineChart(data: stats.elevationChartData, color: Colors.green, unit: "m"),

                    const SizedBox(height: 24),

                    _buildHeader("Activity Breakdown"),

                    StatsPieChart(typeCounts: stats.activityTypeCounts),

                    const SizedBox(height: 50),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
      ),
    );
  }
}
