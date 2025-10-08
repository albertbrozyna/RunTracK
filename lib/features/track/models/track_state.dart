import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/enums/tracking_state.dart';
import '../../profile/models/settings.dart';

class TrackState extends ChangeNotifier {
  Icon gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
  MapController? mapController;
  TrackingState trackingState;
  List<LatLng> trackedPath;
  double totalDistance;
  Duration accumulatedTime = Duration.zero;
  DateTime startTime;
  Duration elapsedTime;
  Timer? timer;
  DateTime? lastPositionTime; // Time of the last position
  double calories;
  double avgSpeed; // km/h
  double currentSpeedValue; // km/h
  double elevationGain; // m
  int steps;

  StreamSubscription<Position>? positionStream;
  final Distance distanceCalculator = Distance(); // To calculate distance between points
  LatLng? currentPosition;
  Position? latestPosition;
  bool followUser = true;

  final locationSettings = LocationSettings(
    // Get the best accuracy
    accuracy: AppSettings.locationAccuracy,
    // The location will update after at least 5 meters
    distanceFilter: AppSettings.updateLocationDistance,
  );

  TrackState({
    required this.mapController,
    List<LatLng>? trackedPath,
    double? totalDistance,
    TrackingState? trackingState,
    DateTime? startTime,
    Duration? elapsedTime,
    double? calories,
    double? avgSpeed, // km/h
    double? currentSpeedValue, // km/h
    double? elevationGain, // m
    int? steps,
    this.currentPosition,
  }) : trackedPath = trackedPath ?? [],
       trackingState = trackingState ?? TrackingState.stopped,
       totalDistance = totalDistance ?? 0.0,
       elapsedTime = elapsedTime ?? Duration.zero,
       startTime = startTime ?? DateTime.now(),
       calories = calories ?? 0.0,
       avgSpeed = avgSpeed ?? 0.0,
       currentSpeedValue = currentSpeedValue ?? 0.0,
       elevationGain = elevationGain ?? 0.0,
       steps = steps ?? 0;

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    positionStream?.cancel();
    positionStream = null;
    super.dispose();
  }

  void updateGpsIcon() async {
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
    } else if (latestPosition == null) {
      gpsIcon = Icon(Icons.signal_cellular_0_bar_outlined, color: Colors.grey, size: 24);
    } else {
      double accuracy = latestPosition!.accuracy;
      if (accuracy <= 5) {
        gpsIcon = Icon(Icons.signal_cellular_alt, size: 24, color: Colors.green);
      } else if (accuracy <= 15) {
        gpsIcon = Icon(Icons.signal_cellular_alt_2_bar_sharp, size: 24, color: Colors.orange);
      } else if (accuracy <= 25) {
        gpsIcon = Icon(Icons.signal_cellular_alt_1_bar_sharp, size: 24, color: Colors.red);
      } else {
        gpsIcon = Icon(Icons.signal_cellular_0_bar, color: Colors.redAccent, size: 24);
      }
    }

    notifyListeners();
  }

  /// Function to start timer
  void _startTimer() {
    // Cancel previous timer if running
    timer?.cancel();

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      elapsedTime = accumulatedTime + DateTime.now().difference(startTime);
      notifyListeners();
    });
  }

  /// Stop timer
  void _stopTimer() {
    timer?.cancel();
    timer = null;
  }

  void _createPositionStream() {
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      final latLng = LatLng(position.latitude, position.longitude);
      latestPosition = position;
      if (currentPosition != null) {
        // Calculate distance from last position
        double dist = distanceCalculator.as(LengthUnit.Meter, currentPosition!, latLng);
        totalDistance += dist;

        final deltaTime = lastPositionTime != null ? DateTime.now().difference(lastPositionTime!).inSeconds.toDouble() : 1.0;

        if (deltaTime > 0) {
          // to km/h from meters
          currentSpeedValue = (dist / deltaTime) * 3.6;
        }

        if (position.altitude > (latestPosition?.altitude ?? 0)) {
          // Elevation gain
          elevationGain += position.altitude - (latestPosition?.altitude ?? 0);
        }

        avgSpeed = (elapsedTime.inSeconds > 0)
            ? (totalDistance / 1000) / (elapsedTime.inSeconds / 3600)
            : 0.0;
        steps = (totalDistance / 0.78).round(); // Steps
      }

      lastPositionTime = DateTime.now();

      currentPosition = latLng;
      trackedPath.add(latLng);

      // Move map to follow current location
      if (trackingState == TrackingState.running && followUser) {
        mapController?.move(latLng, mapController!.camera.zoom);
      }
      notifyListeners();
    });
  }

  /// Start tracking route
  void startTracking() {
    // Setting starting parameters
    trackedPath.clear();
    totalDistance = 0.0;
    elapsedTime = Duration.zero;
    accumulatedTime = Duration.zero;
    startTime = DateTime.now();
    trackingState = TrackingState.running;
    calories = 0.0;
    avgSpeed = 0.0;
    currentSpeedValue = 0.0;
    elevationGain = 0.0;
    steps = 0;
    lastPositionTime = DateTime.now();
    _startTimer();
    _createPositionStream();
    notifyListeners();
  }

  // Function to resume tracking
  void resumeTracking() {
    // Resume tracking
    if (positionStream?.isPaused == true) {
      positionStream!.resume();
    } else {
      positionStream?.cancel();
      _createPositionStream();
    }
    startTime = DateTime.now();
    // Restart timer
    _startTimer();
    {
      trackingState = TrackingState.running;
    }
    notifyListeners();
  }

  void pauseTracking() {
    if (positionStream == null) {
      return;
    }
    // Pause stream
    positionStream!.pause();
    // Pause timer
    _stopTimer();
    accumulatedTime += DateTime.now().difference(startTime);

    trackingState = TrackingState.paused;
    notifyListeners();
  }

  /// Stop tracking
  void stopTracking() {
    // TODO TO DELETE
    if (trackedPath.isEmpty) {
      trackedPath.add(LatLng(56, 56));
    }
    trackingState = TrackingState.stopped;
    positionStream?.cancel();
    positionStream = null;
    _stopTimer();
    trackingState = TrackingState.stopped;
    notifyListeners();
  }
}
