import 'package:flutter/material.dart';
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

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
              );
              if (picked != null) {
                _fromDate = picked.start;
                _toDate = picked.end;
                _loadStats();
              }
            },
          )
        ],
      ),
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
            if (stats.totalActivities == 0) {
              return const Center(child: NoItemsMsg(textMessage: "No activities in the selected period."));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  StatsSummaryGrid(stats: stats),

                  const SizedBox(height: 30),

                  _buildHeader("Cumulative Distance (Progress)"),
                  StatsLineChart(
                    data: stats.cumulativeDistanceData ,
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
                  StatsLineChart(
                    data: stats.elevationChartData,
                    color: Colors.green,
                    unit: "m",
                  ),

                  const SizedBox(height: 24),


                  _buildHeader("Activity Breakdown"),

                  StatsPieChart(typeCounts: stats.activityTypeCounts),

                  const SizedBox(height: 50),
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
        child: Text(title, textAlign: TextAlign.center,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: AppColors.white)),
      ),
    );
  }
}