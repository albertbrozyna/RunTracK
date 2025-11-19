import 'package:flutter/material.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
import '../../../../core/models/activity.dart';

class CompetitionFinishBanner extends StatelessWidget {
  final Competition competition;
  final Activity activity;

  const CompetitionFinishBanner({
    super.key,
    required this.competition,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final double runDistance = activity.totalDistance ?? 0.0;
    final Duration runTime = Duration(seconds: activity.elapsedTime ?? 0);

    final double targetDistance = competition.distanceToGo;

    final Duration targetTime = (competition.maxTimeToCompleteActivityHours == 0 && competition.maxTimeToCompleteActivityMinutes == 0) ? const Duration(days: 365) : Duration(hours: competition.maxTimeToCompleteActivityHours!, minutes: competition.maxTimeToCompleteActivityMinutes!);

    bool distanceMet = runDistance >= targetDistance;
    bool timeMet = runTime <= targetTime;

    if (!distanceMet) {
      return _buildFailDistance(runDistance, targetDistance);
    } else if (!timeMet) {
      return _buildFailMaxTime(runTime, targetTime);
    } else {
      return _buildSuccess();
    }
  }

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.yellow, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "COMPETITION COMPLETED!",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  "You have successfully finished this run.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildFailDistance(double current, double target) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_run, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DISTANCE NOT MET",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Ran: ${(current / 1000).toStringAsFixed(2)} km / Goal: ${(target).toStringAsFixed(2)} km",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailMaxTime(Duration current, Duration limit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_off_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TIME LIMIT EXCEEDED",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Time: ${_formatDuration(current)} / Limit: ${_formatDuration(limit)}",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes h";
  }
}