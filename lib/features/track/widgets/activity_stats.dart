import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../services/activity_service.dart';

class RunStats extends StatelessWidget {
  final double totalDistance;
  final String pace;
  final Duration elapsedTime;
  final double? avgSpeed; // km/h
  final int? steps;
  final double? elevation;
  final double? calories;
  final DateTime? startTime;


  const RunStats({super.key, required this.totalDistance, required this.pace, required this.elapsedTime,this.avgSpeed,this.calories,this.steps,this.startTime,this.elevation});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.14,
      minChildSize: 0.14,
      maxChildSize: 1,
      builder: (context, scrollController) => Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(bottom: 10),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
            child: Column(
              children: [
                // Arrow up icon
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.keyboard_arrow_up_rounded, size: 36, color: Colors.white),
                ),
                GridView.count(
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  children: [
                    _buildStatCard("Time", ActivityService.formatElapsedTime(elapsedTime), Icon(Icons.timer)),
                    _buildStatCard("Distance", '${(totalDistance / 1000).toStringAsFixed(2)} km', Icon(Icons.social_distance)),
                    _buildStatCard("Pace", pace, Icon(Icons.man)),
                    if(calories != null)
                      _buildStatCard("Calories", '${calories?.toStringAsFixed(0)} kcal', Icon(Icons.local_fire_department)),
                    if(avgSpeed != null)
                      _buildStatCard("Avg Speed", '${avgSpeed?.toStringAsFixed(1)} km/h', Icon(Icons.speed)),
                    if(steps != null)
                      _buildStatCard("Steps", steps.toString(), Icon(Icons.directions_walk)),
                    if(elevation != null)
                      _buildStatCard("Elevation", '${elevation?.toStringAsFixed(0)} m', Icon(Icons.terrain)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildStatCard(String title, String value, Icon icon) {
  return Container(
    width: 100, // fixed width for uniformity
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(8)),
    child: Column(
      children: [
        icon,
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
