import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/widgets/stat_card.dart';


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
        decoration: BoxDecoration(color: AppColors.third),
        margin: EdgeInsets.only(bottom: 10),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(left: AppUiConstants.paddingTextFields,right: AppUiConstants.paddingTextFields,bottom: AppUiConstants.paddingTextFields),
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
                    StatCard(title: "Time", value: ActivityService.formatElapsedTime(elapsedTime), icon: Icon(Icons.timer)),
                    StatCard(title:"Distance",value: '${(totalDistance / 1000).toStringAsFixed(2)} km', icon:Icon(Icons.social_distance)),
                    StatCard(title:"Pace",value: pace,icon: Icon(Icons.man)),
                    if(calories != null)
                      StatCard(title:"Calories",value: '${calories?.toStringAsFixed(0)} kcal',icon:  Icon(Icons.local_fire_department)),
                    if(avgSpeed != null)
                      StatCard(title:"Avg Speed",value: '${avgSpeed?.toStringAsFixed(1)} km/h',icon: Icon(Icons.speed)),
                    if(steps != null)
                      StatCard(title:"Steps",value: steps.toString(), icon:Icon(Icons.directions_walk)),
                    if(elevation != null)
                      StatCard(title:"Elevation",value: '${elevation?.toStringAsFixed(0)} m',icon: Icon(Icons.terrain)),
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

