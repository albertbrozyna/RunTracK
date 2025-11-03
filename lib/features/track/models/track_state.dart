import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/enums/tracking_state.dart';

import '../../../common/utils/app_data.dart';
import '../../../main.dart';
import 'location_update.dart';

class TrackState extends ChangeNotifier {

  double totalDistance = 0.0;
  double lastLat = 0.0;
  double lastLng = 0.0;

  TrackState() {
  }

  Future<void> startRun() async {
    trackingState= TrackingState.running;
    notifyListeners();
  }

  Future<void> stopRun() async {
    trackingState = TrackingState.stopped;
    notifyListeners();
  }


  Icon gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
  MapController? mapController;
  TrackingState trackingState = TrackingState.stopped;
  //
  List<LatLng> trackedPath = [];
  // final Distance distanceCalculator = Distance();
  Position? latestPosition;
  DateTime? startTime;
  Duration elapsedTime = Duration.zero;
  double? elevationGain;
  double? calories;
  double? avgSpeed;
  double? currentSpeedValue;
  int? steps;
  double? pace;
  bool followUser = true;
  LatLng? currentPosition;
  DateTime? startOfTheActivity;
  // double positionAccuracy;
  // bool clearFields = false;
  // Timer? _gpsTimer; // Gps timer to fetch gps signal if we are not received data from background service
  // DateTime _lastUpdateFromTask = DateTime.fromMillisecondsSinceEpoch(0);
  // bool _setupInitalized = false;
  // // bool timerStartAdd = false; // Start adding time to elapsed time to sync timers
  //
  // TrackState({
  //   this.mapController,
  //   List<LatLng>? trackedPath,
  //   this.trackingState = TrackingState.stopped,
  //   this.totalDistance = 0.0,
  //   DateTime? startTime,
  //   Duration? elapsedTime,
  //   this.calories = 0.0,
  //   this.avgSpeed = 0.0,
  //   this.currentSpeedValue = 0.0,
  //   this.elevationGain = 0.0,
  //   this.steps = 0,
  //   this.pace = 0.0,
  //   this.followUser = true,
  //   this.currentPosition,
  //   this.positionAccuracy = 0.0,
  // }) : trackedPath = trackedPath ?? [],
  //      startTime = startTime ?? DateTime.now(),
  //      elapsedTime = elapsedTime ?? Duration.zero,
  //      startOfTheActivity = DateTime.now() {
  //   initialize();
  //   getCurrentState();
  // }
  //
  // @override
  // void dispose() {
  //   super.dispose();
  //   _gpsTimer?.cancel();
  //   _gpsTimer = null;
  // }
  //
  // Future<void> _setupCommunication() async {
  //   if(_setupInitalized ==  false){
  //     FlutterForegroundTask.initCommunicationPort();
  //     FlutterForegroundTask.addTaskDataCallback((data) {
  //       if (data is Map<String, dynamic>) {
  //         final update = LocationUpdate.fromJson(data);
  //
  //         if(update.type == 'S'){ // Init all data
  //           trackingState = update.trackingState ?? TrackingState.stopped;
  //           trackedPath.addAll(update.trackedPath!);
  //           elapsedTime = update.elapsedTime ?? Duration.zero;
  //           totalDistance = update.totalDistance;
  //           calories = update.calories;
  //           avgSpeed = update.avgSpeed;
  //           elevationGain = update.elevationGain;
  //           steps = update.steps;
  //           pace = update.pace;
  //           positionAccuracy = update.positionAccuracy;
  //           _lastUpdateFromTask = DateTime.now();
  //           timerStartAdd = true;
  //         }else if(update.type == 'U'){ // Normal update
  //           trackedPath.add(LatLng(update.lat, update.lng));
  //           totalDistance = update.totalDistance;
  //           calories = update.calories;
  //           avgSpeed = update.avgSpeed;
  //           elevationGain = update.elevationGain;
  //           steps = update.steps;
  //           pace = update.pace;
  //           positionAccuracy = update.positionAccuracy;
  //           _lastUpdateFromTask = DateTime.now();
  //         }else if(update.type == 'E') { // End of activity
  //           trackingState = update.trackingState ?? TrackingState.stopped;
  //           trackedPath.addAll(update.trackedPath!);
  //           elapsedTime = update.elapsedTime ?? Duration.zero;
  //           totalDistance = update.totalDistance;
  //           calories = update.calories;
  //           avgSpeed = update.avgSpeed;
  //           elevationGain = update.elevationGain;
  //           steps = update.steps;
  //           pace = update.pace;
  //           positionAccuracy = update.positionAccuracy;
  //           _lastUpdateFromTask = DateTime.now();
  //         }
  //
  //         updateGpsIcon();
  //         notifyListeners();
  //
  //         if(followUser && mapController != null){  // Move map
  //           mapController?.move(LatLng(update.lat, update.lng),mapController?.camera.zoom ?? 15);
  //         }
  //       }
  //     });
  //     _setupInitalized = true;
  //   }
  //   }
  //
  //
  //
  //
  // void initialize()async  {
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //
  //   if(isRunning){  // If service is running, set communication
  //     _setupCommunication();
  //     getCurrentState();
  //   }
  //
  //   _gpsTimer?.cancel();  // Timer to fetch check a gps signal if service is off
  //   _gpsTimer = Timer.periodic(Duration(seconds: 1), (_) async {
  //     if(trackingState == TrackingState.running && timerStartAdd){
  //       elapsedTime += const Duration(seconds: 1);  // Add seconds here to make timer smooth
  //     }
  //     print("timerMain ${elapsedTime.inSeconds}");
  //     notifyListeners();
  //
  //     final now = DateTime.now();
  //     if (now.difference(_lastUpdateFromTask) > Duration(seconds: 5)) {
  //       await _fetchLocation(); // Get gps location
  //     }
  //   });
  //
  // }
  //
  // Future<void> _fetchLocation() async {
  //   try {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) return;
  //
  //     Position position = await Geolocator.getCurrentPosition(
  //       locationSettings: LocationSettings(
  //         accuracy: LocationAccuracy.best,
  //       ),
  //     );
  //
  //     latestPosition = position;
  //     positionAccuracy = position.accuracy;
  //
  //     if(followUser && mapController != null){
  //       mapController?.move(LatLng(latestPosition!.latitude, latestPosition!.longitude),mapController?.camera.zoom ?? 15);
  //     }
  //
  //     updateGpsIcon();  // Update gps
  //
  //     notifyListeners(); // Notify Ui about all changes
  //   } catch (e) {
  //     print('GPS error: $e');
  //   }
  // }
  //
  // void updateGpsIcon() async {
  //   bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
  //
  //   if (!gpsEnabled) {
  //     gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
  //     return;
  //   }
  //   if (positionAccuracy <= 5) {
  //     gpsIcon = Icon(Icons.signal_cellular_alt, size: 24, color: Colors.green);
  //   } else if (positionAccuracy <= 15) {
  //     gpsIcon = Icon(Icons.signal_cellular_alt_2_bar_sharp, size: 24, color: Colors.orange);
  //   } else if (positionAccuracy <= 25) {
  //     gpsIcon = Icon(Icons.signal_cellular_alt_1_bar_sharp, size: 24, color: Colors.red);
  //   } else {
  //     gpsIcon = Icon(Icons.signal_cellular_0_bar, color: Colors.redAccent, size: 24);
  //   }
  // }
  //
  // void clearAllFields() {
  //     trackedPath.clear();
  //     totalDistance = 0.0;
  //     startTime = DateTime.now();
  //     elapsedTime = Duration.zero;
  //     latestPosition = null;
  //     elevationGain = 0.0;
  //     calories = 0.0;
  //     avgSpeed = 0.0;
  //     currentSpeedValue = 0.0;
  //     steps = 0;
  //     pace = 0.0;
  //     followUser = true;
  //     currentPosition = null;
  // }
  //
  // static Future<Position> determinePosition() async {
  //   // Check permissions
  //   LocationPermission permission = await Geolocator.checkPermission();
  //
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       throw Exception("Location permissions are denied");
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     throw Exception(
  //       "Location permissions are permanently denied. Enable them in settings.",
  //     );
  //   }
  //
  //   // Check GPS is enabled
  //   final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     throw Exception("Location services are disabled. Enable GPS.");
  //   }
  //
  //   // Get location
  //   return await Geolocator.getCurrentPosition(
  //     locationSettings: LocationSettings(
  //       accuracy: LocationAccuracy.best,
  //       distanceFilter: 10,
  //     ),
  //   );
  // }
  //
  // static void initForegroundTask(){
  //   FlutterForegroundTask.init(
  //     androidNotificationOptions: AndroidNotificationOptions(
  //       channelId: 'run_track_channel_gps_track',
  //       channelName: 'Location Tracking',
  //       channelDescription: 'Tracking location in background',
  //       channelImportance: NotificationChannelImportance.HIGH,
  //       priority: NotificationPriority.HIGH,
  //     ),
  //     iosNotificationOptions: const IOSNotificationOptions(
  //       showNotification: true,
  //       playSound: false,
  //     ),
  //     foregroundTaskOptions: ForegroundTaskOptions(
  //         autoRunOnBoot: true,
  //         allowWakeLock: true,
  //         allowWifiLock: true,
  //         eventAction: ForegroundTaskEventAction.repeat(
  //             5000 // 5 s
  //         )
  //     ),
  //   );
  // }

  // /// Calculate and format pace
  static String formatPace(double totalDistance, Duration elapsedTime) {
    if (totalDistance < 10) return "--"; // Not enough data
    double km = totalDistance / 1000;
    double pace = elapsedTime.inSeconds / km;
    int paceMin = (pace / 60).floor();
    int paceSec = (pace % 60).round();
    return "$paceMin:${paceSec.toString().padLeft(2, '0')} min/km";
  }

  // /// Start foreground location service
  // Future<void> startLocationService() async {
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //   clearAllFields();
  //   notifyListeners();
  //   if (!isRunning) {
  //     await FlutterForegroundTask.startService(
  //       notificationTitle: 'Activity tracking',
  //       notificationText: 'RunTracK tracks your activity!',
  //       callback: startCallback,
  //     );
  //   }
  //   trackingState = TrackingState.running;
  //   _setupCommunication();
  // }

  // /// Pause the foreground service
  //  Future<void> pauseLocationService() async {
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //   trackingState = TrackingState.paused;
  //   notifyListeners();
  //   if (isRunning) {
  //     FlutterForegroundTask.sendDataToTask({
  //       'action': 'pause'
  //     });
  //
  //     await FlutterForegroundTask.updateService(
  //       notificationTitle: 'Tracking paused',
  //       notificationText: 'Location tracking is temporarily paused',
  //     );
  //   }
  // }

  // /// Stop the foreground service
  // Future<void> stopLocationService() async {
  //   trackingState = TrackingState.stopped;
  //   notifyListeners();
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //   if (isRunning) {
  //     timerStartAdd = false;
  //     FlutterForegroundTask.sendDataToTask({
  //       'action':'stop'
  //     });
  //   }
  // }

  // /// Resume location service
  // Future<void> resumeLocationService() async {
  //   trackingState = TrackingState.running;
  //   notifyListeners();
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //   if (isRunning) {
  //     FlutterForegroundTask.sendDataToTask({
  //       'action':'resume'
  //     });
  //   }
  // }

  // /// Check if service is active on start and if it is, request data from it
  // Future<void> getCurrentState()async {
  //   bool isRunning = await FlutterForegroundTask.isRunningService;
  //   if (isRunning) {
  //     clearAllFields();
  //     FlutterForegroundTask.sendDataToTask({
  //       'action':'sendAllData'
  //     });
  //   }
  // }

  // Future<void> startLocationService() async {
  //   await AppData.runTracker.init();
  //   await AppData.runTracker.startTracking();
  //   trackingState = TrackingState.running;
  //   notifyListeners();
  // }
  //
  // Future<void> stopLocationService() async {
  //   await AppData.runTracker.stopTracking();
  //   trackingState = TrackingState.stopped;
  //   notifyListeners();
  // }

}
