import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/tracking_state.dart';
import '../../../../core/models/activity.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/track_state.dart';
import '../pages/activity_summary.dart';

class ActionButtons extends StatefulWidget {
  final TextEditingController activityController;

  const ActionButtons({super.key, required this.activityController});

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  final ValueNotifier<double> _finishProgressNotifier = ValueNotifier(0.0);
  Timer? _finishTimer;

  void handleStopTracking() async {
    await TrackState.trackStateInstance.stopRun();

    if (mounted) {
      print("Pushing page");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivitySummary(
            firstName: AppData.instance.currentUser?.firstName ?? '',
            lastName: AppData.instance.currentUser?.lastName ?? '',
            readonly: false,
            currentUserCompetition: AppData.instance.currentUserCompetition,
            activityData: Activity(
              uid: AppData.instance.currentUser!.uid,
              activityType: widget.activityController.text.trim(),
              avgSpeed: TrackState.trackStateInstance.avgSpeed,
              calories: TrackState.trackStateInstance.calories,
              steps: TrackState.trackStateInstance.steps,
              elevationGain: TrackState.trackStateInstance.elevationGain,
              trackedPath: TrackState.trackStateInstance.trackedPath,
              elapsedTime: TrackState.trackStateInstance.elapsedTime.inSeconds.toInt(),
              totalDistance: TrackState.trackStateInstance.totalDistance,
              pace: TrackState.trackStateInstance.pace,
              startTime: TrackState.trackStateInstance.startTime,
              createdAt: DateTime.now(),
            ),
          ),
        ),
      );
    }
    TrackState.trackStateInstance.refreshUi();
  }

  @override
  Widget build(BuildContext context) {
    switch (TrackState.trackStateInstance.trackingState) {
      case TrackingState.stopped:
        return CustomButton(
          backgroundColor: AppColors.secondary,
          text: AppLocalizations.of(context)!.trackScreenStartTraining,
          onPressed: () => TrackState.trackStateInstance.startRun(context),
        );

      case TrackingState.running:
        return CustomButton(
          width: 50,
          text: "Stop",
          onPressed: TrackState.trackStateInstance.pauseRun,
        );

      case TrackingState.paused:
        return Column(
          children: [
            Row(
              children: [
                // Resume Button
                Expanded(
                  child: CustomButton(
                    height: 50,
                    text: "Resume",
                    onPressed: TrackState.trackStateInstance.resumeRun,
                  ),
                ),
                const SizedBox(width: AppUiConstants.horizontalSpacingButtons),

                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      _finishProgressNotifier.value = 0.0;
                      _finishTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
                        _finishProgressNotifier.value += 0.04;
                        if (_finishProgressNotifier.value >= 1.0) {
                          _finishTimer?.cancel();
                          handleStopTracking();
                        }
                      });
                    },
                    onLongPressEnd: (_) {
                      _finishTimer?.cancel();
                      _finishProgressNotifier.value = 0.0;
                    },
                    child: SizedBox(
                      height: 50,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomButton(
                            text: "",
                            onPressed: () {}, // Normal tap disabled
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _finishProgressNotifier,
                            builder: (context, progress, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppUiConstants.borderRadiusButtons,
                                ),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 50,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.third),
                                  backgroundColor: Colors.transparent,
                                ),
                              );
                            },
                          ),
                          // Text overlay
                          const Center(
                            child: Text(
                              "Finish",
                              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
