import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/features/track/pages/activity_summary.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../common/enums/tracking_state.dart';
import '../../../common/utils/app_data.dart';
import '../../../common/utils/permission_utils.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}


class _TrackScreenState extends State<TrackScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _trackedPath = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _followUser = true;
  final Distance _distanceCalculator = Distance();
  double _totalDistance = 0.0; // In meters
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  TrackingState _trackingState = TrackingState.stopped;
  final LatLng defaultLocation = LatLng(52.2297, 21.0122);

  // Var that checks if gps is enabled
  bool _gpsEnabled = true;

  // Activity name loaded from
  String? activityName;

  // Activity controller
  TextEditingController activityController = TextEditingController();

  // Current position
  LatLng? _currentPosition;

  double _finishProgress = 0.0; // Progress for long press on Finish
  Timer? _finishTimer;

  Position? _latestPosition;

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchLastActivity();
  }

  // Update gps status
  Future<void> _updateGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _gpsEnabled = serviceEnabled;
    });
  }

  Future<void> fetchLastActivity() async {
    activityName = await PreferencesService.loadString("keyLastUserActivity");

    // Set activity and return
    if (activityName != null) {
      // Check if user list contains this activity
      if(AppData.currentUser?.activityNames?.contains(activityName) == false){
        // No last activity on the list, select first
        activityName = AppData.currentUser?.activityNames?.first;
      }

      setState(() {
        activityController.text = activityName!;
      });
      return;
    }

    if (activityName == null) {
      try {
        if(!UserService.isUserLoggedIn()){
          UserService.signOutUser();
          if(mounted){
            Navigator.of(context).pushReplacementNamed('/start');
          }
          return;
        }

        // Save the activityName locally
        if (activityName != null) {
          await PreferencesService.saveString("keyLastUserActivity", activityName!);
        }
      } catch (e) {
        print("Error fetching activity: $e");
      }
    }
  }

  // Function on leading pressed menu button
  void onLeadingPressed(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  // Function to start tracking
  void _pauseTracking() {
    // Pause stream
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.pause();
    }
    // Pause timer
    _timer?.cancel();
    setState(() {
      _trackingState = TrackingState.paused;
    });
  }

  /// Function to start timer
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if(_startTime != null){
          _elapsedTime = DateTime.now().difference(_startTime!);
        }
      });
    });
  }

  // Function to resume tracking
  void _resumeTracking() {
    // Resume tracking
    if (_positionStreamSubscription != null && _positionStreamSubscription!.isPaused) {
      _positionStreamSubscription!.resume();
    } else {
      // TODO If the subscription was canceled, you need to recreate it
    }
    // Restart timer
    _startTimer();

    setState(() {
      _trackingState = TrackingState.running;
    });
  }

  void _stopTracking() {
    // TODO TO DELETE
    if(_trackedPath.isEmpty){
      _trackedPath.add(LatLng(56, 56));
    }
    _trackingState = TrackingState.stopped;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          elapsedTime: _elapsedTime,
          totalDistance: _totalDistance,
          trackedPath: List<LatLng>.from(_trackedPath),
          activityType: activityName ?? "Unknown",
          startTime: _startTime,
        ),
      ),
    );

    // Pause timer
    // _timer?.cancel();
    // _positionStreamSubscription = null;
    // setState(() {
    //   //_trackedPath.clear();
    // });
  }

  void _startTracking() {
    // Setting starting parameters
    setState(() {
      _trackedPath.clear();
      _totalDistance = 0.0;
      _elapsedTime = Duration.zero;
      _startTime = DateTime.now();

      _trackedPath.clear();
      _trackingState = TrackingState.running;
    });

    // Setting timer
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_trackingState == TrackingState.running) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });

    const locationSettings = LocationSettings(
      // Get the best accuracy
      accuracy: LocationAccuracy.best,
      // The location will update after at least 5 meters
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            await _updateGpsStatus();
            final latLng = LatLng(position.latitude, position.longitude);
            setState(() {
              _latestPosition = position;
              if (_currentPosition != null) {
                // Calculate distance from last postion
                _totalDistance += _distanceCalculator.as(
                  LengthUnit.Meter,
                  _currentPosition!,
                  latLng,
                );
              }
              _currentPosition = latLng;
              _trackedPath.add(latLng);
            });
            // Move map to follow current location
            if (_trackingState == TrackingState.running && _followUser) {
              _mapController.move(latLng, _mapController.camera.zoom);
            }
          },
        );
  }

  // Controls with pace time and start/stop buttons
  Widget _buildControls() {
    // Stats of the run, pace and distance

    // Different button depends on tracking state
    switch (_trackingState) {
      case TrackingState.stopped:
        return SizedBox(
          height: 50.0,
          width: double.infinity,
          child: CustomButton(
            text: AppLocalizations.of(context)!.trackScreenStartTraining,
            onPressed: _startTracking,
            gradientColors: [
              Color(0xFFFFA726), // Light Orange
              Color(0xFFFF5722),
            ],
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
                onPressed: _pauseTracking,
                gradientColors: [
                  Color(0xFFFFB74D), // Lighter Orange
                  Color(0xFFFF9800), // Bright Orange
                  Color(0xFFF57C00), // Darker Orange
                ],
              ),
            ),
          ],
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
                  onPressed: _resumeTracking,
                  gradientColors: [
                    Color(0xFFFFB74D), // Lighter Orange
                    Color(0xFFFF9800), // Bright Orange
                    Color(0xFFF57C00), // Darker Orange
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10), // Space between buttons
            // Finish Button with long-press progress
            Expanded(
              child: SizedBox(
                height: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient button
                    CustomButton(
                      text: "", // We'll show the text in overlay
                      onPressed: () {}, // Disable normal tap
                      gradientColors: [
                        Color(0xFFFFB74D),
                        Color(0xFFFF9800),
                        Color(0xFFF57C00),
                      ],
                    ),
                    // Progress bar overlay with full width
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: _finishProgress,
                        minHeight: 50,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.withValues(
                            alpha: 0.6,
                          ), // bright enough to see
                        ),
                      ),
                    ),

                    // Gesture detector for long press
                    GestureDetector(
                      onLongPressStart: (_) {
                        _finishProgress = 0.0;
                        _finishTimer = Timer.periodic(
                          Duration(milliseconds: 50),
                          (timer) {
                            setState(() {
                              _finishProgress +=
                                  0.02; // slower for smoother fill
                              if (_finishProgress >= 1.0) {
                                _finishTimer?.cancel();
                                _stopTracking(); // Finish run
                              }
                            });
                          },
                        );
                      },
                      onLongPressEnd: (_) {
                        _finishTimer?.cancel();
                        setState(() {
                          _finishProgress = 0.0; // Reset if released early
                        });
                      },
                      child: Center(
                        child: Text(
                          "Finish",
                          style: TextStyle(
                            color: Colors.white,
                            //fontWeight: FontWeight.bold,
                            //fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  String get _formattedPace {
    if (_totalDistance < 10) return "--"; // Not enough data
    double km = _totalDistance / 1000;
    double pace = _elapsedTime.inSeconds / km;
    int paceMin = (pace / 60).floor();
    int paceSec = (pace % 60).round();
    return "$paceMin:${paceSec.toString().padLeft(2, '0')} min/km";
  }

  /// Method invoked when user wants to select change activity
  void onTapActivity() async {
    final selectedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityChoose(currentActivity: activityController.text.trim()),
      ),
    );

    // If the user selected something, update the TextField
    if (selectedActivity != null && selectedActivity.isNotEmpty) {
      activityController.text = selectedActivity;
    }
  }

  /// Method that returns a gps icon depends on signal
  Icon getGpsIcon(double accuracy) {
    // If gps is disabled
    if (!_gpsEnabled) {
      // GPS is turned off
      return Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
    }
    if (accuracy <= 5) {
      return Icon(Icons.signal_cellular_alt, size: 24, color: Colors.green);
    } else if (accuracy <= 15) {
      return Icon(
        Icons.signal_cellular_alt_2_bar_sharp,
        size: 24,
        color: Colors.orange,
      );
    } else if (accuracy <= 25) {
      return Icon(
        Icons.signal_cellular_alt_1_bar_sharp,
        size: 24,
        color: Colors.red,
      );
    } else {
      return Icon(
        Icons.signal_cellular_0_bar,
        color: Colors.redAccent,
        size: 24,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom fab location to set a fab
      floatingActionButtonLocation: CustomFabLocation(
          xOffset: 20,yOffset: 70
      ),
      body: Stack(
        children: [
          /// Main column content
          Column(
            children: [
              // Activity type + GPS row
              Row(
                children: [
                  SizedBox(width: 10.0),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _latestPosition != null
                          ? getGpsIcon(_latestPosition!.accuracy)
                          : Icon(
                              Icons.signal_cellular_0_bar_outlined,
                              color: Colors.grey,
                              size: 24,
                            ),
                      Text("GPS"),
                    ],
                  ),
                  Expanded(
                    child: TextField(
                      controller: activityController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.zero,
                        ),
                        filled: true,
                        fillColor: Color(0xFFFFF3E0),
                        suffixIcon: IconButton(
                          onPressed: () => onTapActivity(),
                          icon: Icon(Icons.settings, size: 26),
                        ),
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
                    initialCenter: _currentPosition ?? defaultLocation,
                    initialZoom: 15.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.runtrack',
                    ),
                    if (_trackedPath.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trackedPath,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          /// RunStats positioned as draggable sheet
          if (_trackingState == TrackingState.running)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RunStats(
                  totalDistance: _totalDistance,
                  pace: _formattedPace,
                  elapsedTime: _elapsedTime,
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
      ),

      floatingActionButton: FloatingActionButton(

        onPressed: () {
          setState(() {
            _followUser = !_followUser;
            if (_followUser && _currentPosition != null) {
              _mapController.move(
                _currentPosition!,
                _mapController.camera.zoom,
              );
            }
          });
        },
        child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
      ),
    );
  }
}
