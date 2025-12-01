import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/widgets/stat_card.dart';

class RunStats extends StatelessWidget {
  final double totalDistance;
  final String pace;
  final Duration elapsedTime;
  final double? avgSpeed;
  final int? steps;
  final double? elevationGain;
  final double? elevationLoss;
  final double? calories;
  final DateTime? startTime;

  const RunStats({
    super.key,
    required this.totalDistance,
    required this.pace,
    required this.elapsedTime,
    this.avgSpeed,
    this.calories,
    this.steps,
    this.startTime,
    this.elevationGain,
    this.elevationLoss,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    const double peekHeightInPixels =20.0;

    final double initialSheetSize = (peekHeightInPixels / screenHeight).clamp(0.05, 1.0);

    return DraggableScrollableSheet(
      initialChildSize: initialSheetSize,
      minChildSize: initialSheetSize,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.third,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppUiConstants.paddingTextFields,
                right: AppUiConstants.paddingTextFields,
                bottom: AppUiConstants.paddingTextFields,
                top: 20,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  GridView.count(
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(title: "Time", value: ActivityService.formatElapsedTime(elapsedTime), icon: const Icon(Icons.timer)),
                      StatCard(title: "Distance", value: '${(totalDistance / 1000).toStringAsFixed(2)} km', icon: const Icon(Icons.social_distance)),
                      StatCard(title: "Pace", value: pace, icon: const Icon(Icons.man)),
                      if (calories != null)
                        StatCard(title: "Calories", value: '${calories?.toStringAsFixed(0)} kcal', icon: const Icon(Icons.local_fire_department)),
                      if (avgSpeed != null)
                        StatCard(title: "Avg Speed", value: '${avgSpeed?.toStringAsFixed(1)} km/h', icon: const Icon(Icons.speed)),
                      if (steps != null)
                        StatCard(title: "Steps", value: steps.toString(), icon: const Icon(Icons.directions_walk)),
                      if (elevationGain != null)
                        StatCard(title: "Elevation gain", value: '${elevationGain?.toStringAsFixed(0)} m', icon: const Icon(Icons.terrain)),
                      if (elevationLoss != null)
                        StatCard(title: "Elevation loss", value: '${elevationLoss?.toStringAsFixed(0)} m', icon: const Icon(Icons.terrain)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}