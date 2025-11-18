import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/competitions/data/models/competition_result.dart';
import 'package:run_track/features/competitions/data/models/result_record.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';

class CompetitionResultsPage extends StatefulWidget {
  final CompetitionResult? result;
  final String competitionId;

  const CompetitionResultsPage({super.key, this.result, required this.competitionId});

  @override
  State<CompetitionResultsPage> createState() => _CompetitionResultsPageState();
}

class _CompetitionResultsPageState extends State<CompetitionResultsPage> {
  late CompetitionResult? _displayResult;
  bool error = false;
  bool isLoading = false;
  List<ResultRecord>? top3;


  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  void initializeAsync() async {
    setState(() {
      isLoading = true;
    });
    if (widget.result == null) {
      _displayResult = await CompetitionService.fetchResult(widget.competitionId);

      if (_displayResult == null) {
        setState(() {
          _displayResult = CompetitionResult(competitionId: "", ranking: []);
        });
      }

      // Find top 3 places
      top3 = _displayResult!.ranking.take(3).toList();
    } else {
      _displayResult = widget.result;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Competition results")),
        body: PageContainer(assetPath: AppImages.appBg5, child: const AppLoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Competition results")),
      body: PageContainer(
        assetPath: AppImages.appBg5,
        child: _displayResult!.ranking.isEmpty
            ? _buildEmptyState()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: const Text(
                        "Results:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.builder(
                        clipBehavior: Clip.none,
                        itemCount: _displayResult!.ranking.length,
                        itemBuilder: (context, index) {
                          return _buildResultTile(_displayResult!.ranking[index],index + 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResultTile(ResultRecord record, int place) {
    Color placeColor;
    double scale = 1.0;
    bool isPodium = false;
    // Colors for results

    if (record == top3!.first) {
      placeColor = const Color(0xFFFFD700); // 1 place
      scale = 1.05;
      isPodium = true;
    } else if (record == top3![1]) {
      placeColor = const Color(0xFFC0C0C0); // 2 place
      isPodium = true;
    } else if (record == top3![2]) {
      placeColor = const Color(0xFFCD7F32); // 3  place
      isPodium = true;
    } else {
      placeColor = AppColors.primary; // Normal bg
      isPodium = true;
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: isPodium
              ? placeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isPodium ? Border.all(color: placeColor, width: 2) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // Rank
          leading: Container(
            width: 60,
            height: 60 ,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPodium ? placeColor : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Text(
              "#$place",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPodium ? Colors.black : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            "${record.firstName} ${record.lastName}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            record.finished ? "${(record.distance / 1000).toStringAsFixed(2)} km" : "Not finished",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
          // Time
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
              const SizedBox(height: 2),
              Text(
                record.finished ? record.formattedTime : "DNF",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text("No results", style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }
}
