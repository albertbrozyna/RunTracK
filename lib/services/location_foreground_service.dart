import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:run_track/common/utils/permission_utils.dart';

import '../features/track/models/location_update.dart';

class LocationTaskHandler extends TaskHandler {
  final List<LatLng> _trackedPath = [];
  bool _granted = false;
  final Distance distanceCalculator = Distance(); // To calculate distance between points
  Position? latestPosition;
  double totalDistance = 0;
  Duration accumulatedTime = Duration.zero;
  DateTime startTime = DateTime.now();
  Duration elapsedTime = Duration.zero;

  double _elevationGain = 0;
  double calories = 0;
  double avgSpeed = 0;
  double currentSpeedValue = 0;
  int steps = 0;
  double pace = 0; // min/km

  Future<void> saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_state.json');
      await file.writeAsString(jsonEncode(toJson()), flush: true); // Write it immediately to the file, not wait
    } catch (e) {
      print("Error: " + e.toString());
    }
  }

  Future<bool> checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _granted = await checkPermissions();
    _trackedPath.clear();
    totalDistance = 0;
    startTime = DateTime.now();
    elapsedTime = Duration.zero;
    latestPosition = null;
    _elevationGain = 0;
    calories = 0;
    avgSpeed = 0;
    currentSpeedValue = 0;
    currentSpeedValue = 0;
    pace = 0;
    steps = 0;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    saveToFile();
    return;
  }

  @override
  void onNotificationPressed() {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_granted) {
      try {
        LatLng latestLatLng;
        Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.best));
        latestLatLng = LatLng(position.latitude, position.longitude);

        if (latestPosition != null) {
          final double distanceBetweenPositions = distanceCalculator.as(
            LengthUnit.Meter,
            LatLng(latestPosition!.latitude, latestPosition!.longitude),
            latestLatLng,
          );
          totalDistance += distanceBetweenPositions;

          // Calc time difference and sum it to total elapsed time
          final deltaTime = DateTime.now().difference(latestPosition!.timestamp);
          elapsedTime += deltaTime;

          final double deltaAltitude = position.altitude - (latestPosition!.altitude);
          if (deltaAltitude > 0) _elevationGain += deltaAltitude;
          avgSpeed = elapsedTime.inSeconds > 0 ? (totalDistance / 1000) / (elapsedTime.inSeconds / 3600) : 0.0;
          pace = avgSpeed > 0 ? (60 / avgSpeed) : 0.0;

          steps = (totalDistance / 0.78).round();
        }

        latestPosition = position;
        if (_trackedPath.isEmpty || distanceCalculator.as(LengthUnit.Meter, _trackedPath.last, latestLatLng) > 2) {
          _trackedPath.add(latestLatLng);
        }

        FlutterForegroundTask.sendDataToMain(LocationUpdate(
          lat: position.latitude,
          lng: position.longitude,
          totalDistance: totalDistance,
          elapsedTime: elapsedTime,
          elevationGain: _elevationGain,
          avgSpeed: avgSpeed,
          pace: pace,
          steps: steps,
          calories: calories,
        ).toJson());
      } catch (e) {
        print("Error fetching location: $e");
      }
    }
  }


}


  extension LocationTaskHandlerJson on LocationTaskHandler {
  Map<String, dynamic> toJson() {
    return {
      'trackedPath': _trackedPath
          .map((e) => {'lat': e.latitude, 'lng': e.longitude})
          .toList(),
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime.inSeconds,
      'accumulatedTime': accumulatedTime.inSeconds,
      'startTime': startTime.toIso8601String(),
      'elevationGain': _elevationGain,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'currentSpeedValue': currentSpeedValue,
      'steps': steps,
      'pace': pace,
      'latestPosition': latestPosition != null
          ? {
        'lat': latestPosition!.latitude,
        'lng': latestPosition!.longitude,
        'altitude': latestPosition!.altitude,
        'timestamp': latestPosition!.timestamp?.toIso8601String(),
      }
          : null,
    };
  }

  static LocationTaskHandler fromJson(Map<String, dynamic> json) {
    final handler = LocationTaskHandler();

    // Track points
    if (json['trackedPath'] != null) {
      handler._trackedPath.addAll((json['trackedPath'] as List)
          .map((e) => LatLng(e['lat'], e['lng'])));
    }

    handler.totalDistance = (json['totalDistance'] ?? 0).toDouble();
    handler.elapsedTime = Duration(seconds: json['elapsedTime'] ?? 0);
    handler.accumulatedTime = Duration(seconds: json['accumulatedTime'] ?? 0);
    handler.startTime = DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String());
    handler._elevationGain = (json['elevationGain'] ?? 0).toDouble();
    handler.calories = (json['calories'] ?? 0).toDouble();
    handler.avgSpeed = (json['avgSpeed'] ?? 0).toDouble();
    handler.currentSpeedValue = (json['currentSpeedValue'] ?? 0).toDouble();
    handler.steps = json['steps'] ?? 0;
    handler.pace = (json['pace'] ?? 0).toDouble();

    // Latest position
    if (json['latestPosition'] != null) {
      final lp = json['latestPosition'];
      handler.latestPosition = Position(
        latitude: lp['lat'],
        longitude: lp['lng'],
        altitude: lp['altitude'] ?? 0.0,
        accuracy: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        timestamp: lp['timestamp'] != null ? DateTime.parse(lp['timestamp']) : DateTime.now(),
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0
      );
    }

    return handler;
  }
}