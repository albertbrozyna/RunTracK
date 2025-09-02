import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/theme/ui_constants.dart';

class RunStats extends StatelessWidget {
  final double totalDistance;
  final String pace;
  final Duration elapsedTime;

  const RunStats({
    Key? key,
    required this.totalDistance,
    required this.pace,
    required this.elapsedTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.60,
      builder: (context, scrollController) => Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(bottom: 10),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
            child: Column(
              children: [
                // Arrow up icon
                Padding(padding: EdgeInsets.all(1),
                child:    Icon(Icons.keyboard_arrow_up_rounded,  size: 30,))
              ,
                GridView.count(
                  childAspectRatio: 1.7,
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  children: [
                    _buildStatCard(
                      "Time:",
                      '${AppUtils.formatDuration(elapsedTime)}',Icon(Icons.timer)
                    ),
                    // TODO change icon
                    _buildStatCard(
                      "Distance:",
                      '${(totalDistance / 1000).toStringAsFixed(2)} km',Icon(Icons.social_distance)
                    ),
                    _buildStatCard("Pace:", '$pace',Icon(Icons.man))
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

Widget _buildStatCard(String title, String value,Icon icon) {
  return Container(
    width: 100, // fixed width for uniformity
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        icon,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    )
  );
}
