import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/profile/models/settings.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/features/track/pages/activity_summary.dart';
import 'package:run_track/features/track/services/track_service.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../common/enums/tracking_state.dart';
import '../../../common/utils/app_data.dart';
import '../../../common/utils/permission_utils.dart';
import '../models/track_state.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  _TrackScreenState createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  late TrackState _trackState;
  final MapController _mapController = MapController();
  bool _followUser = true;
  TextEditingController activityController = TextEditingController();
  String? activityName = AppData.currentUser?.activityNames?.first; // Assign default on the start
  double _finishProgress = 0.0; // Progress for long press on Finish
  Timer? _finishTimer;
  Timer? _gpsTimer; // Gps timer to refresh gps

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _trackState.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _trackState = TrackState(mapController: _mapController);
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _trackState.updateGpsIcon();
    });
    initialize();
  }

  Future<void> initialize() async {
    activityName = await ActivityService.fetchLastActivityFromPrefs();
  }


  void handleStopTracking() {
    _trackState.stopTracking();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          elapsedTime: _trackState.elapsedTime,
          totalDistance: _trackState.totalDistance,
          trackedPath: List<LatLng>.from(_trackState.trackedPath),
          activityType: activityName ?? "Unknown",
          startTime: _trackState.startTime,
        ),
      ),
    );
  }

  // Controls with pace time and start/stop buttons
  Widget _buildControls() {
    switch (_trackState.trackingState) {
      case TrackingState.stopped:
        return SizedBox(
          height: 50.0,
          width: double.infinity,
          child: CustomButton(
            text: AppLocalizations.of(context)!.trackScreenStartTraining,
            onPressed: _trackState.startTracking,
            gradientColors: [
              const Color(0xFFFFA726),
              const Color(0xFFFF5722),
            ],
          ),
        );

      case TrackingState.running:
        return SizedBox(
          height: 50.0,
          width: double.infinity,
          child: CustomButton(
            text: "Stop",
            onPressed: _trackState.pauseTracking,
            gradientColors: const [
              Color(0xFFFFB74D),
              Color(0xFFFF9800),
              Color(0xFFF57C00),
            ],
          ),
        );

      case TrackingState.paused:
        return Row(
          children: [
            // Resume Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: CustomButton(
                  text: "Resume",
                  onPressed: _trackState.resumeTracking,
                  gradientColors: const [
                    Color(0xFFFFB74D),
                    Color(0xFFFF9800),
                    Color(0xFFF57C00),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppUiConstants.horizontalSpacingButtons),

            // Finish Button (long press)
            Expanded(
              child: GestureDetector(
                onLongPressStart: (_) {
                  _finishProgress = 0.0;
                  _finishTimer = Timer.periodic(
                    const Duration(milliseconds: 50),
                        (timer) {
                      setState(() {
                        _finishProgress += 0.02; // smooth fill
                        if (_finishProgress >= 1.0) {
                          _finishTimer?.cancel();
                          _trackState.stopTracking(); // Finish run
                        }
                      });
                    },
                  );
                },
                onLongPressEnd: (_) {
                  _finishTimer?.cancel();
                  setState(() {
                    _finishProgress = 0.0;
                  });
                },
                child: SizedBox(
                  height: 50,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomButton(
                        text: "",
                        onPressed: () {}, // Normal tap disabled
                        gradientColors: const [
                          Color(0xFFFFB74D),
                          Color(0xFFFF9800),
                          Color(0xFFF57C00),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: _finishProgress,
                          minHeight: 50,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.red.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      // Text overlay
                      const Center(
                        child: Text(
                          "Finish",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            //fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom fab location to set a fab
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 70),
      body: AnimatedBuilder(
        animation: _trackState,
        builder: (BuildContext context, _) {
          return Stack(
            children: [
              /// Main column content
              Column(
                children: [
                  // Activity type + GPS row
                  Row(
                    children: [
                      SizedBox(width: 10.0),
                      Column(mainAxisSize: MainAxisSize.min, children: [_trackState.gpsIcon, Text("GPS")]),
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
                        initialCenter: _trackState.currentPosition ?? AppSettings.defaultLocation,
                        initialZoom: 15.0,
                        interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.runtrack',
                        ),
                        if (_trackState.trackedPath.isNotEmpty)
                          PolylineLayer(
                            polylines: [Polyline(points: _trackState.trackedPath, strokeWidth: 4.0, color: Colors.blue)],
                          ),
                        if (_trackState.currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _trackState.currentPosition!,
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
              if (_trackState.trackingState == TrackingState.running)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: RunStats(
                      totalDistance: _trackState.totalDistance,
                      pace: TrackService.formatPace(_trackState.totalDistance, _trackState.elapsedTime),
                      elapsedTime: _trackState.elapsedTime,
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
                  height: 60,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppUiConstants.paddingTextFields,
                      right: AppUiConstants.paddingTextFields,
                      top: AppUiConstants.paddingTextFields,
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
            if (_followUser && _trackState.currentPosition != null) {
              _mapController.move(_trackState.currentPosition!, _mapController.camera.zoom);
            }
          });
        },
        child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
      ),
    );
  }
}
