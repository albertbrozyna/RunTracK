import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/enums/tracking_state.dart';

import 'location_update.dart';

class TrackState extends ChangeNotifier {
  Icon gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
  MapController? mapController;
  TrackingState trackingState;

  List<LatLng> trackedPath;
  final Distance distanceCalculator = Distance();
  Position? latestPosition;
  double totalDistance;
  DateTime startTime;
  Duration elapsedTime;
  double elevationGain;
  double calories;
  double avgSpeed;
  double currentSpeedValue;
  int steps;
  double pace;
  bool followUser;
  LatLng? currentPosition;
  DateTime startOfTheActivity;
  double positionAccuracy;

  Timer? _gpsTimer; // Gps timer to fetch gps signal if we are not received data from background service
  DateTime _lastUpdateFromTask = DateTime.fromMillisecondsSinceEpoch(0);

  TrackState({
    this.mapController,
    List<LatLng>? trackedPath,
    this.trackingState = TrackingState.stopped,
    this.totalDistance = 0.0,
    DateTime? startTime,
    Duration? elapsedTime,
    this.calories = 0.0,
    this.avgSpeed = 0.0,
    this.currentSpeedValue = 0.0,
    this.elevationGain = 0.0,
    this.steps = 0,
    this.pace = 0.0,
    this.followUser = true,
    this.currentPosition,
    this.positionAccuracy = 0.0,
  }) : trackedPath = trackedPath ?? [],
       startTime = startTime ?? DateTime.now(),
       elapsedTime = elapsedTime ?? Duration.zero,
       startOfTheActivity = DateTime.now() {
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initialize() {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map<String, dynamic>) {
        final update = LocationUpdate.fromJson(data);
        // Update tracking state if it's different
        if(update.trackingState != null && update.trackingState != trackingState){
          trackingState = update.trackingState!;
        }

        if(update.trackedPath != null){
          trackedPath.addAll(update.trackedPath!);
        }else{
          trackedPath.add(LatLng(update.lat, update.lng));
        }
        totalDistance += update.totalDistance;
        calories += update.calories;
        avgSpeed = update.avgSpeed;
        elevationGain += update.elevationGain;
        steps += update.steps;
        pace = update.pace;
        positionAccuracy = update.positionAccuracy;
        trackingState = trackingState;
        _lastUpdateFromTask = DateTime.now();
        updateGpsIcon();
        notifyListeners();
      }
    });

    _gpsTimer?.cancel();  // Timer to fetch check a gps signal if service is off
    _gpsTimer = Timer.periodic(Duration(seconds: 4), (_) async {
      final now = DateTime.now();
      if (now.difference(_lastUpdateFromTask) > Duration(seconds: 5)) {
        await _fetchLocation();
      }
    });

  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      latestPosition = position;
      positionAccuracy = position.accuracy;
      updateGpsIcon();

      notifyListeners();
    } catch (e) {
      print('GPS error: $e');
    }
  }

  void updateGpsIcon() async {
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
    }
    if (positionAccuracy <= 5) {
      gpsIcon = Icon(Icons.signal_cellular_alt, size: 24, color: Colors.green);
    } else if (positionAccuracy <= 15) {
      gpsIcon = Icon(Icons.signal_cellular_alt_2_bar_sharp, size: 24, color: Colors.orange);
    } else if (positionAccuracy <= 25) {
      gpsIcon = Icon(Icons.signal_cellular_alt_1_bar_sharp, size: 24, color: Colors.red);
    } else {
      gpsIcon = Icon(Icons.signal_cellular_0_bar, color: Colors.redAccent, size: 24);
    }
    notifyListeners();
  }

  void clearAllFields() {
      trackingState = TrackingState.stopped;
      trackedPath.clear();
      totalDistance = 0.0;
      startTime = DateTime.now();
      elapsedTime = Duration.zero;
      latestPosition = null;
      elevationGain = 0.0;
      calories = 0.0;
      avgSpeed = 0.0;
      currentSpeedValue = 0.0;
      steps = 0;
      pace = 0.0;
      followUser = true;
      currentPosition = null;
  }
}
