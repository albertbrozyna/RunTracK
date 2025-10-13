import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/profile/models/settings.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/features/track/pages/activity_summary.dart';
import 'package:run_track/features/track/services/track_service.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/theme/preference_names.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:run_track/common/enums/visibility.dart';
import '../../../common/enums/tracking_state.dart';
import '../../../common/utils/app_data.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  TrackScreenState createState() => TrackScreenState();
}

class TrackScreenState extends State<TrackScreen> {
  final MapController _mapController = MapController();
  bool _followUser = true;
  TextEditingController activityController = TextEditingController();
  String? activityName = AppData.currentUser?.activityNames?.first; // Assign default on the start
  final ValueNotifier<double> _finishProgressNotifier = ValueNotifier(0.0);
  Timer? _finishTimer;
  Timer? _gpsTimer; // Gps timer to refresh gps

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      AppData.trackState.updateGpsIcon();
    });

    final lastActivity = await ActivityService.fetchLastActivityFromPrefs();
    setState(() {
      activityName = lastActivity;
      activityController.text = lastActivity;
    });
  }

  void handleStopTracking() {
    AppData.trackState.stopTracking();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          readonly: false,
          activityData: Activity(
            uid: AppData.currentUser!.uid,
            activityType: activityController.text.trim(),
            avgSpeed: AppData.trackState.avgSpeed,
            calories: AppData.trackState.calories,
            steps: AppData.trackState.steps,
            elevationGain: AppData.trackState.elevationGain,
            trackedPath: AppData.trackState.trackedPath,
            elapsedTime: AppData.trackState.elapsedTime.inSeconds.toInt(),
            totalDistance: AppData.trackState.totalDistance,
            startTime: AppData.trackState.startOfTheActivity,
            createdAt: AppData.trackState.startOfTheActivity,
            title: "",
            description: "",
          ),
        ),
      ),
    );
  }

  // Controls with pace time and start/stop buttons
  Widget _buildControls() {
    switch (AppData.trackState.trackingState) {
      case TrackingState.stopped:
        return SizedBox(
          height: 50.0,
          width: double.infinity,
          child: CustomButton(
            text: AppLocalizations.of(context)!.trackScreenStartTraining,
            onPressed: AppData.trackState.startTracking,
            gradientColors: [const Color(0xFFFFA726), const Color(0xFFFF5722)],
          ),
        );

      case TrackingState.running:
        return Column(
          children: [
            SizedBox(
              height: 50.0,
              width: double.infinity,
              child: CustomButton(
                text: "Stop",
                onPressed: AppData.trackState.pauseTracking,
                gradientColors: const [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00)],
              ),
            ),
          ],
        );

      case TrackingState.paused:
        return Column(
          children: [
            Row(
              children: [
                // Resume Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: CustomButton(
                      text: "Resume",
                      onPressed: AppData.trackState.resumeTracking,
                      gradientColors: const [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                  ),
                ),
                const SizedBox(width: AppUiConstants.horizontalSpacingButtons),

                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      _finishProgressNotifier.value = 0.0;
                      _finishTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
                        _finishProgressNotifier.value += 0.02;
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
                            gradientColors: const [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00)],
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _finishProgressNotifier,
                            builder: (context, progress, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 50,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red.withValues(alpha: 0.6)),
                                ),
                              );
                            },
                          ),
                          // Text overlay
                          const Center(
                            child: Text(
                              "Finish",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  /// Method invoked when user wants to select change activity
  void onTapActivity() async {
    final selectedActivity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivityChoose(currentActivity: activityController.text.trim())),
    );

    // If the user selected something, update the TextField
    if (selectedActivity != null && selectedActivity.isNotEmpty) {
      activityController.text = selectedActivity;
      AppData.lastActivityString = selectedActivity;
      // Save it to local preferences
      PreferencesService.saveString(PreferenceNames.lastUsedPreference, selectedActivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom fab location to set a fab
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 120),
      body: AnimatedBuilder(
        animation: AppData.trackState,
        builder: (BuildContext context, _) {
          return Stack(
            children: [
              Column(
                children: [
                  // Activity type  GPS row
                  Row(
                    children: [
                      SizedBox(width: 10.0),
                      Column(mainAxisSize: MainAxisSize.min, children: [AppData.trackState.gpsIcon, Text("GPS")]),
                      Expanded(
                        child: TextField(
                          controller: activityController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
                            filled: true,
                            fillColor: Color(0xFFFFF3E0),
                            suffixIcon: IconButton(onPressed: () => onTapActivity(), icon: Icon(Icons.settings, size: 26)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Expanded map
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: AppData.trackState.currentPosition ?? AppSettings.defaultLocation,
                        initialZoom: 15.0,
                        interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.runtrack',
                        ),
                        if (AppData.trackState.trackedPath.isNotEmpty && (AppData.trackState.trackingState == TrackingState.paused ||
                            AppData.trackState.trackingState == TrackingState.running))
                          PolylineLayer(
                            polylines: [Polyline(points: AppData.trackState.trackedPath, strokeWidth: 4.0, color: Colors.blue)],
                          ),
                        if (AppData.trackState.currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: AppData.trackState.currentPosition!,
                                width: 40,
                                height: 40,
                                child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              /// RunStats positioned as draggable sheet
              if (AppData.trackState.trackingState == TrackingState.running || AppData.trackState.trackingState == TrackingState.paused)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: RunStats(
                      totalDistance: AppData.trackState.totalDistance,
                      pace: TrackService.formatPace(AppData.trackState.totalDistance, AppData.trackState.elapsedTime),
                      elapsedTime: AppData.trackState.elapsedTime,
                      startTime: AppData.trackState.startTime,
                      avgSpeed: AppData.trackState.avgSpeed,
                      calories: AppData.trackState.calories,
                      steps: AppData.trackState.steps,
                      elevation: AppData.trackState.elevationGain,
                    ),
                  ),
                ),

              /// Controls above everything else
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  height:
                      AppData.trackState.trackingState == TrackingState.running || AppData.trackState.trackingState == TrackingState.paused
                      ? 76.0
                      : 60.0,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppUiConstants.paddingTextFields,
                      right: AppUiConstants.paddingTextFields,
                      top: AppUiConstants.paddingTextFields,
                      bottom:
                          AppData.trackState.trackingState == TrackingState.running ||
                              AppData.trackState.trackingState == TrackingState.paused
                          ? 16
                          : 0,
                    ),
                    child: _buildControls(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _followUser = !_followUser;
            if (_followUser && AppData.trackState.currentPosition != null) {
              _mapController.move(AppData.trackState.currentPosition!, _mapController.camera.zoom);
            }
          });
        },
        child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
      ),
    );
  }
}
