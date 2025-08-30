import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/common/widgets/side_menu.dart';
import 'package:run_track/common/widgets/top_bar.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';
import 'package:run_track/features/track/pages/activity_summary.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';
import '../../../common/utils/permission_utils.dart';
import 'package:run_track/common/widgets/navigation_bar.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}

enum TrackingState { stopped, running, paused }

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

  // Activity name loaded from
  String? activityName = null;
  // Activity controller
  TextEditingController activityController = new TextEditingController();

  // Current position
  LatLng? _currentPosition;

  double _finishProgress = 0.0; // Progress for long press on Finish
  Timer? _finishTimer;

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchLastActivity();
  }

  Future<void> fetchLastActivity() async {
    activityName = await AppUtils.loadString("keyLastUserActivity");

    if (activityName == null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return; // No logged-in user
        }
        final uid = user.uid;

        // Fetch user document
        final docSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey("activities")) {
            final activities = List<String>.from(data["activities"]);
            if (activities.isNotEmpty) {
              activityName = activities.first; // Get first activity
            }
          }
        }

        // Save the activityName locally
        if (activityName != null) {
          await AppUtils.saveString("keyLastUserActivity", activityName!);
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

  // Function to get location permission
  Future<void> _getLocation() async {
    try {
      final position = await LocationService.determinePosition();
      setState(() {
        _currentPosition = LatLng(position!.latitude, position.longitude);
      });

      // Move and zoom map to current location
      final newPos = LatLng(position!.latitude, position.longitude);
      _mapController.move(newPos, 15.0);
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Function to start tracking
  void _pauseTracking() {
    _positionStreamSubscription?.pause();
    // Pause timer
    _timer?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _trackingState = TrackingState.paused;
    });
  }

  // Function to resume tracking
  void _resumeTracking() {
    _positionStreamSubscription?.resume();
    setState(() {
      _trackingState = TrackingState.running;
    });
  }

  void _stopTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          elapsedTime: _elapsedTime,
          totalDistance: _totalDistance,
          trackedPath: _trackedPath,
          activityType: activityName!,
        ),
      ),
    );
    _positionStreamSubscription?.cancel();
    // Pause timer
    _timer?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _trackingState = TrackingState.stopped;
      _trackedPath.clear();
    });
  }

  void _startTracking() {
    // Setting starting parameters
    setState(() {
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
          (Position position) {
            final latLng = LatLng(position.latitude, position.longitude);
            setState(() {
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
            // Show stats and cancel button while running
            RunStats(totalDistance: _totalDistance, pace: _formattedPace),
            //
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
                          Colors.red.withOpacity(0.6), // bright enough to see
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

  void onTapActivity(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityChoose()));
  }

  Widget _buildMapWithButton() {
    return Stack(
      children: [
        Column(
          children: [
            TextField(
              controller: activityController,
              onTap: () => onTapActivity(),
              decoration: InputDecoration(
                hint: Text("Select activity"),
                border: OutlineInputBorder(
                  borderRadius: AppUiConstants.borderRadiusTextFields,
                )

              ),
            )
            ,
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Current location or default position
                  // TODO Add here a variable with default location
                  initialCenter: _currentPosition ?? defaultLocation,
                  initialZoom: 15.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    // z is zoom x,y are longitude and latitude
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Different domains used to speed up downloading a maps, just different servers
                    // TODO to change
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              // Bottom buttons
              child: _buildControls(),
            ),
          ],
        ),
        // Track button on the right
        Positioned(
          bottom: 90,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _followUser = !_followUser;
                // If we change state on follow user is true we center map on user
                if (_followUser && _currentPosition != null) {
                  _mapController.move(
                    _currentPosition!,
                    _mapController.camera.zoom,
                    // TODO add smooth move
                  );
                }
              });
            },
            // Changing icon depends on following user
            child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMapWithButton();
  }
}
