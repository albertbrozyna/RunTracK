import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:run_track/common/enums/tracking_state.dart';
import 'package:run_track/common/utils/app_constants.dart';

import '../models/location_update.dart';

class TrackingTaskHandler extends TaskHandler{
  TrackingState trackingState;
  List<LatLng> trackedPath;
  bool _granted = false;
  final Distance distanceCalculator = Distance(); // To calculate distance between points
  Position? latestPosition;
  double totalDistance;
  DateTime startTime;
  Duration elapsedTime;
  Timer? _elapsedTimer;
  double elevationGain;
  double calories;
  double avgSpeed;
  double currentSpeedValue;
  int steps;
  double pace; // min/km
  Duration totalTime;
  int secondsSinceLastSave;


  TrackingTaskHandler({
    this.trackingState = TrackingState.running,
    List<LatLng>? trackedPath,
    this.totalDistance = 0,
    this.elapsedTime = Duration.zero,
    this.totalTime = Duration.zero,
    DateTime? startTime,
    this.calories = 0,
    this.avgSpeed = 0,
    this.currentSpeedValue = 0,
    this.elevationGain = 0,
    this.steps = 0,
    this.pace = 0,
    this.secondsSinceLastSave = 0,
  }) : trackedPath = trackedPath ?? [],
       startTime = startTime ?? DateTime.now();

  Future<bool> checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  void sendAllDataToMain(String type) {
    FlutterForegroundTask.sendDataToMain(
      LocationUpdate(
        type: type,  //  Data on the end
        trackingState: trackingState,
        lat: latestPosition?.latitude ?? 0.0,
        lng: latestPosition?.longitude ?? 0.0,
        totalDistance: totalDistance,
        elapsedTime: elapsedTime,
        elevationGain: elevationGain,
        avgSpeed: avgSpeed,
        pace: pace,
        steps: steps,
        calories: calories,
        trackedPath: trackedPath,
        positionAccuracy: latestPosition?.accuracy ?? 0.0,
      ).toJson(),
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _granted = await checkPermissions();
    print("hereGT1");

    if(_granted == false){
      print("no permissions");
    }

    // TrackingTaskHandlerFile.loadFromFile()
    //     .then((trackingHandler) {
    //       if (trackingHandler != null && false &&  (trackingHandler.trackingState == TrackingState.running || trackingHandler.trackingState == TrackingState.paused)) {
    //         trackingState = trackingHandler.trackingState;
    //         trackedPath = List<LatLng>.from(trackingHandler.trackedPath);
    //         totalDistance = trackingHandler.totalDistance;
    //         startTime = trackingHandler.startTime;
    //         elapsedTime = trackingHandler.elapsedTime;
    //         latestPosition = trackingHandler.latestPosition;
    //         elevationGain = trackingHandler.elevationGain;
    //         calories = trackingHandler.calories;
    //         avgSpeed = trackingHandler.avgSpeed;
    //         currentSpeedValue = trackingHandler.currentSpeedValue;
    //         steps = trackingHandler.steps;
    //         pace = trackingHandler.pace;
    //
    //         sendAllDataToMain('S'); // S means synchroize
    //       } else {
    //         trackingState = TrackingState.running;
    //         trackedPath.clear();
    //         totalDistance = 0;
    //         startTime = DateTime.now();
    //         elapsedTime = Duration.zero;
    //         latestPosition = null;
    //         elevationGain = 0;
    //         calories = 0;
    //         avgSpeed = 0;
    //         currentSpeedValue = 0;
    //         pace = 0;
    //         steps = 0;
    //         sendAllDataToMain('S');
    //       }
    //     })
    //     .catchError((error) {
    //       print('Error loading tracking data: $error');
    //     });

    sendAllDataToMain('S');
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (trackingState == TrackingState.running) {
        elapsedTime += const Duration(seconds: 1);
        print("timerSecond ${elapsedTime.inSeconds}");


        secondsSinceLastSave++;

        if (secondsSinceLastSave >= 30) {
          //saveToFile();
          secondsSinceLastSave = 0;
        }
      }
    });
    print("Foreground service started!");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _elapsedTimer?.cancel();
    return;
  }

  @override
  void onNotificationPressed() {}

  @override
  void onReceiveData(Object data)async {
    final map = data as Map<String, dynamic>;
    switch (map['action']) {
      case 'pause':
        trackingState = TrackingState.paused;
        break;
      case 'resume':
        trackingState = TrackingState.running;
        break;
      case 'stop':
        trackingState = TrackingState.stopped;
        _elapsedTimer?.cancel();
        totalTime = DateTime.now().difference(startTime);
        sendAllDataToMain("E"); // On the end
        await deleteFile();
        await Future.delayed(const Duration(milliseconds: 500)); // Pause before sending to main
        await FlutterForegroundTask.stopService();
        break;
      case 'sendAllData':
        sendAllDataToMain("S"); // send with synchronize flag
        await deleteFile();
        break;
    }
    super.onReceiveData(data);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
      print("Repeat outside");
    if (_granted && trackingState == TrackingState.running) {
      print("enteered inside");
      try {
        LatLng latestLatLng;
        Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.best,distanceFilter: 10));
        latestLatLng = LatLng(position.latitude, position.longitude);

        if (latestPosition != null) {
          final double distanceBetweenPositions = distanceCalculator.as(
            LengthUnit.Meter,
            LatLng(latestPosition!.latitude, latestPosition!.longitude),
            latestLatLng,
          );
          totalDistance += distanceBetweenPositions;


          final double deltaAltitude = position.altitude - (latestPosition!.altitude);
          if (deltaAltitude > 0) elevationGain += deltaAltitude;
          avgSpeed = elapsedTime.inSeconds > 0 ? (totalDistance / 1000) / (elapsedTime.inSeconds / 3600) : 0.0;
          pace = avgSpeed > 0 ? (60 / avgSpeed) : 0.0;

          steps = (totalDistance / 0.78).round();
        }

        latestPosition = position;
        if (trackedPath.isEmpty || distanceCalculator.as(LengthUnit.Meter, trackedPath.last, latestLatLng) > 1) {
          trackedPath.add(latestLatLng);
        }

        FlutterForegroundTask.sendDataToMain(
          LocationUpdate(
            type: 'U', // Time update
            lat: position.latitude,
            lng: position.longitude,
            totalDistance: totalDistance,
            elevationGain: elevationGain,
            avgSpeed: avgSpeed,
            pace: pace,
            steps: steps,
            calories: calories,
            positionAccuracy: latestPosition?.accuracy ?? 0.0,
          ).toJson(),
        );

      } catch (e) {
        print("Error fetching location: $e");
      }
    }
  }
}

extension TrackingTaskHandlerJson on TrackingTaskHandler {
  Map<String, dynamic> toJson() {
    return {
      'trackingState': trackingState.name,
      'trackedPath': trackedPath.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime.inSeconds,
      'startTime': startTime.toIso8601String(),
      'elevationGain': elevationGain,
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
              'timestamp': latestPosition!.timestamp.toIso8601String(),
            }
          : null,
    };
  }

  static TrackingTaskHandler fromJson(Map<String, dynamic> json) {
    List<LatLng> path = [];
    if (json['trackedPath'] != null) {
      path = (json['trackedPath'] as List).map((e) => LatLng(e['lat'], e['lng'])).toList();
    }

    Position? latestPos;
    if (json['latestPosition'] != null) {
      final lp = json['latestPosition'];
      latestPos = Position(
        latitude: lp['lat'],
        longitude: lp['lng'],
        altitude: lp['altitude'] ?? 0.0,
        accuracy: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        timestamp: lp['timestamp'] != null ? DateTime.parse(lp['timestamp']) : DateTime.now(),
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    return TrackingTaskHandler(
      trackingState: json['trackingState'] != null
          ? TrackingState.values.firstWhere((e) => e.name == json['trackingState'])
          : TrackingState.stopped,
      trackedPath: path,
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      elapsedTime: Duration(seconds: json['elapsedTime'] ?? 0),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      elevationGain: (json['elevationGain'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      avgSpeed: (json['avgSpeed'] ?? 0).toDouble(),
      currentSpeedValue: (json['currentSpeedValue'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
      pace: (json['pace'] ?? 0).toDouble(),
    )..latestPosition = latestPos;
  }
}

extension TrackingTaskHandlerFile on TrackingTaskHandler {
  Future<void> saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${AppConstants.trackingTaskFilename}');
      await file.writeAsString(jsonEncode(toJson()), flush: true); // Write it immediately to the file, not wait
    } catch (e) {
      print("Error: $e");
    }
  }

  /// Delete a file with a tracking state from memory
  Future<void> deleteFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${AppConstants.trackingTaskFilename}');
      if (await file.exists()) {
        await file.delete();
      } else {
        print('File not found.');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  static Future<TrackingTaskHandler?> loadFromFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory(); // App documents
      final file = File('${dir.path}/${AppConstants.trackingTaskFilename}');
      if (!await file.exists()) {
        return null;
      }
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr);

      return TrackingTaskHandlerJson.fromJson(data);
    } catch (e) {
      print('Error loading track state: $e');
      return null;
    }
  }
}
