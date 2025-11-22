import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/enums/visibility.dart';
import 'package:run_track/core/models/activity.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';
import 'package:run_track/features/track/presentation/pages/activity_summary.dart';
import 'package:run_track/features/track/presentation/widgets/action_buttons.dart';
import 'package:run_track/features/track/presentation/widgets/current_competition_banner.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/preference_names.dart';
import '../../../../core/enums/tracking_state.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/preferences_service.dart';

import '../../data/models/track_state.dart';
import '../widgets/activity_stats.dart';
import '../widgets/fab_location.dart';

//import 'package:flutter_map_animations/flutter_map_animations.dart';

// late final AnimatedMapController _animatedMapController;
//
// @override
// void initState() {
//   super.initState();
//   _animatedMapController = AnimatedMapController(vsync: this);
// }
//
// void moveSmooth(LatLng newPos) {
//   _animatedMapController.animateTo(
//     dest: newPos,
//     zoom: 17,
//     curve: Curves.easeInOut,
//     duration: const Duration(seconds: 1),
//   );
// }

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  TrackScreenState createState() => TrackScreenState();
}

class TrackScreenState extends State<TrackScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _followUser = true;
  TextEditingController activityController = TextEditingController();
  String? activityName = AppData.instance.currentUser?.activityNames
      .first; // Assign default on the start
  late final AnimatedMapController _animatedMapController;


  @override
  void dispose() {
    TrackState.trackStateInstance.removeListener(_onTrackStateChanged);
    TrackState.trackStateInstance.removeListener(_animateMapMovement);
    activityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    TrackState.trackStateInstance.addListener(_onTrackStateChanged);
  }


  void _onTrackStateChanged() {
    final state = TrackState.trackStateInstance;

    if (state.endSync && mounted) {
      state.endSync = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToSummary();
        }
      });
    }
  }

  void _navigateToSummary() {
    final state = TrackState.trackStateInstance;

    final bool isCompetition = state.currentUserCompetition.isNotEmpty;

    final activityData = Activity(
      activityId: "",
      uid: AppData.instance.currentUser?.uid ?? "",
      activityType: activityController.text.toString().trim(),
      title: isCompetition ? "Competition Run" : activityController.text.toString().trim(),
      description: isCompetition ? "Completed competition: ${state.currentUserCompetition}" : "",
      totalDistance: state.totalDistance,
      elapsedTime: state.elapsedTime.inSeconds,
      startTime: state.startTime ?? DateTime.now(),
      trackedPath: List.from(state.trackedPath),
      pace: state.pace ?? 0.0,
      avgSpeed: state.avgSpeed ?? 0.0,
      calories: state.calories ?? 0.0,
      elevationGain: state.elevationGain ?? 0.0,
      elevationLoss: state.elevationLoss ?? 0.0,
      createdAt: DateTime.now(),
      steps: state.steps ?? 0,
      visibility: ComVisibility.me,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          firstName: AppData.instance.currentUser?.firstName ?? '',
          lastName: AppData.instance.currentUser?.lastName ?? '',
          activityData: activityData,
          editMode: false,
          readonly: false,
          currentUserCompetition: isCompetition ? AppData.instance.currentUserCompetition : null,
        ),
      ),
    );
  }

  Future<void> initialize() async {
    if (AppData.instance.currentUserCompetition != null) {
      // Set activity type from competition
      activityController.text = AppData.instance.currentUserCompetition!.name;
    } else {
      final lastActivity = await ActivityService.fetchLastActivityFromPrefs();
      activityController.text = lastActivity;
    }
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );

    TrackState.trackStateInstance.mapController =
        _mapController; // Assign map controller to move the map

    TrackState.trackStateInstance.addListener(_animateMapMovement);
  }

  void _animateMapMovement() {
    if (!_followUser || TrackState.trackStateInstance.currentPosition == null) {
      return;
    }
    _animatedMapController.animateTo(
      dest: TrackState.trackStateInstance.currentPosition!,
      zoom: _mapController.camera.zoom,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 1000), // 1 sec animated move
    );
  }


/// Method invoked when user wants to select change activity
void onTapActivity() async {
  final selectedActivity = await Navigator.pushNamed(
    context,
    AppRoutes.activityChoose,
    arguments: {'currentActivity': activityController.text.trim()},
  );

  // If the user selected something, update the TextField
  if (selectedActivity != null && selectedActivity is String) {
    activityController.text = selectedActivity;
    AppData.instance.lastActivityString = selectedActivity;
    // Save it to local preferences
    PreferencesService.saveString(PreferenceNames.lastUsedPreference, selectedActivity);
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    // Custom fab location to set a fab
    body: AnimatedBuilder(
      animation: TrackState.trackStateInstance,
      builder: (BuildContext context, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Activity type  GPS row
                Row(
                  children: [
                    SizedBox(width: 10.0),
                    Column(mainAxisSize: MainAxisSize.min,
                        children: [TrackState.trackStateInstance.gpsIcon, Text("GPS")]),
                    Expanded(
                      child: TextField(
                        controller: activityController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderSide: BorderSide.none,
                              borderRadius: BorderRadius.zero),
                          suffixIcon: IconButton(
                            onPressed: AppData.instance.currentUserCompetition == null ? () =>
                                onTapActivity() : null,
                            icon: Icon(
                              Icons.edit,
                              size: 26,
                              color: AppData.instance.currentUserCompetition == null ? AppColors
                                  .secondary : Colors.grey.withAlpha(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                CurrentCompetitionBanner(
                    canCheckDetails: TrackState.trackStateInstance.trackingState ==
                        TrackingState.stopped),
                // Expanded map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: TrackState.trackStateInstance.currentPosition ??
                          LatLng(AppConstants.defaultLat, AppConstants.defaultLon),
                      initialZoom: 15.0,
                      interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.runtrack',
                      ),
                      if (TrackState.trackStateInstance.trackedPath.isNotEmpty &&
                          (TrackState.trackStateInstance.trackingState == TrackingState.paused ||
                              TrackState.trackStateInstance.trackingState == TrackingState.running))
                        PolylineLayer(
                          polylines: [Polyline(points: TrackState.trackStateInstance.trackedPath,
                              strokeWidth: 4.0,
                              color: Colors.blue)
                          ],
                        ),
                      if (TrackState.trackStateInstance.currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                                point: TrackState.trackStateInstance.currentPosition!,
                                width: 40,
                                height: 40,
                                child: Icon(Icons.person_pin_circle, color: Colors.red, size: 50),
                                rotate: true
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (TrackState.trackStateInstance.isFinishing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: AppLoadingIndicator(
                    message: "Finalizing...",
                    size: 60,
                    indicatorColor: AppColors.white,
                    messageStyle: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            /// RunStats positioned as draggable sheet
            if (TrackState.trackStateInstance.trackingState == TrackingState.running ||
                TrackState.trackStateInstance.trackingState == TrackingState.paused)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: RunStats(
                    totalDistance: TrackState.trackStateInstance.totalDistance,
                    pace: TrackState.formatPace(TrackState.trackStateInstance.totalDistance,
                        TrackState.trackStateInstance.elapsedTime),
                    elapsedTime: TrackState.trackStateInstance.elapsedTime,
                    startTime: TrackState.trackStateInstance.startTime,
                    avgSpeed: TrackState.trackStateInstance.avgSpeed,
                    calories: TrackState.trackStateInstance.calories,
                    steps: TrackState.trackStateInstance.steps,
                    elevationGain: TrackState.trackStateInstance.elevationGain,
                    elevationLoss: TrackState.trackStateInstance.elevationLoss,
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
                TrackState.trackStateInstance.trackingState == TrackingState.running ||
                    TrackState.trackStateInstance.trackingState == TrackingState.paused
                    ? 76.0
                    : 60.0,
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppUiConstants.paddingTextFields,
                    right: AppUiConstants.paddingTextFields,
                    top: AppUiConstants.paddingTextFields,
                    bottom:
                    TrackState.trackStateInstance.trackingState == TrackingState.running ||
                        TrackState.trackStateInstance.trackingState == TrackingState.paused
                        ? 16
                        : 0,
                  ),
                  child: ActionButtons(activityController: activityController),
                ),
              ),
            ),
          ],
        );
      },
    ),
    floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 120),
    floatingActionButton: FloatingActionButton(
      heroTag: "tag_follow",
      backgroundColor: AppColors.primary,
      onPressed: () {
        setState(() {
          _followUser = !_followUser;
          TrackState.trackStateInstance.followUser = _followUser;
          if (_followUser && TrackState.trackStateInstance.currentPosition != null) {
            _animatedMapController.animateTo(
              dest: TrackState.trackStateInstance.currentPosition!,
              zoom: 17,
            );

          }
        });
      },
      child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed, color: AppColors.white),
    ),
  );
}}
