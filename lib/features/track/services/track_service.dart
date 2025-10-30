import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:run_track/common/enums/tracking_state.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/features/track/models/track_state.dart';

import '../../../main.dart';

class TrackService {
  static Future<Position> determinePosition() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permissions are permanently denied. Enable them in settings.",
      );
    }

    // Check GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled. Enable GPS.");
    }

    // Get location
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    );
  }

  static void initForegroundTask(){
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'run_track_channel_gps_track',
        channelName: 'Location Tracking',
        channelDescription: 'Tracking location in background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
          eventAction: ForegroundTaskEventAction.repeat(
              5000
          )
      ),
    );
  }

  /// Calculate and format pace
  static String formatPace(double totalDistance, Duration elapsedTime) {
    if (totalDistance < 10) return "--"; // Not enough data
    double km = totalDistance / 1000;
    double pace = elapsedTime.inSeconds / km;
    int paceMin = (pace / 60).floor();
    int paceSec = (pace % 60).round();
    return "$paceMin:${paceSec.toString().padLeft(2, '0')} min/km";
  }

  /// Start foreground location service
  Future<void> startLocationService() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      AppData.trackState.trackingState = TrackingState.running;
      await FlutterForegroundTask.startService(
        notificationTitle: 'Tracking is active',
        notificationText: '',
        callback: startCallback,
      );
    }
  }

  /// Pause the foreground service
  static Future<void> pauseLocationService() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      AppData.trackState.trackingState = TrackingState.paused;
      FlutterForegroundTask.sendDataToTask({
        'action': 'pause'
      });

      await FlutterForegroundTask.updateService(
        notificationTitle: 'Tracking paused',
        notificationText: 'Location tracking is temporarily paused',
      );
    }
  }

  /// Stop the foreground service
  static Future<void> stopLocationService() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      AppData.trackState.trackingState = TrackingState.stopped;
      FlutterForegroundTask.sendDataToTask({
        'action':'stop'
      });
    }
  }

  /// Resume location service
  static Future<void> resumeLocationService() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      AppData.trackState.trackingState = TrackingState.running;
      Notidy
      FlutterForegroundTask.sendDataToTask({
        'action':'resume'
      });
    }
  }

  /// Check if service is active on start and if it is, request data from it
  static Future<void> getCurrentState()async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      AppData.trackState.clearAllFields();  // Clear all data from class and update with this from service
      FlutterForegroundTask.sendDataToTask({
        'action':'sendAllData'
      });
    }
  }
}
