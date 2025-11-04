import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/tracking_state.dart';
import 'package:run_track/features/track/models/storage.dart';

import '../models/location_update.dart';

enum ServiceEvent { startService, stopService, update, pause, resume, getState,sync,ready }

@pragma('vm:entry-point')
void onStart(ServiceInstance serviceInstance) async {
  DartPluginRegistrant.ensureInitialized();

  TrackingState trackingState = TrackingState.stopped;
  final double averageStepLength = 0.78;
  final double weightKg = 70;

  List<LatLng> trackedPath = [];
  double totalDistance = 0.0;
  final Distance distanceCalculator = Distance();
  Position? latestPosition;
  Duration elapsedTime = Duration.zero;
  double elevationGain = 0.0;
  double elevationLoss = 0.0;
  double calories = 0.0;
  double avgSpeed = 0.0;
  double currentSpeedValue = 0.0;
  int steps = 0;
  double pace = 0.0;
  LatLng? currentPosition;
  const double maxHumanSpeed = 12.0; // 43 km/h

  Timer? timeTimer;
  StreamSubscription<Position>? positionSubscription;
  StreamSubscription? startSubscription;
  StreamSubscription? stopSubscription;
  StreamSubscription? getStateSubscription;
  StreamSubscription? pauseSubscription;
  StreamSubscription? resumeSubscription;

  try {
    final stats = await Storage.loadStats();
    final savedLocations = await Storage.loadLocations();

    if (stats.isNotEmpty) {
      totalDistance = (stats['totalDistance'] ?? 0.0).toDouble();
      elevationGain = (stats['elevationGain'] ?? 0.0).toDouble();
      elevationLoss = (stats['elevationLoss'] ?? 0.0).toDouble();
      calories = (stats['calories'] ?? 0.0).toDouble();
      avgSpeed = (stats['avgSpeed'] ?? 0.0).toDouble();
      pace = (stats['pace'] ?? 0.0).toDouble();
      steps = (stats['steps'] ?? 0).toInt();
      currentSpeedValue = (stats['currentSpeedValue'] ?? 0.0).toDouble();
      elapsedTime = Duration(seconds: (stats['elapsedTime'] ?? 0).toInt());
    }

    if (savedLocations.isNotEmpty) {
      trackedPath = savedLocations;
      currentPosition = savedLocations.last;
    }
  } catch (e) {}

  // Handle events from UI
  if (serviceInstance is AndroidServiceInstance) {
    // Start service
    startSubscription = serviceInstance.on(ServiceEvent.startService.name).listen((_) {
      trackingState = TrackingState.running;
    });

    // Stop service
    stopSubscription = serviceInstance.on(ServiceEvent.stopService.name).listen((_) async {
      final update = LocationUpdate(
        lat: 0.0,
        lng: 0.0,
        type: 'E', // END
        totalDistance: totalDistance,
        steps: steps,
        elevationGain: elevationGain,
        elevationLoss: elevationLoss,
        avgSpeed: avgSpeed,
        pace: pace,
        calories: calories,
        positionAccuracy: 0.0,
        trackingState: trackingState,
      );
      serviceInstance.invoke(ServiceEvent.sync.name, update.toJson());
      timeTimer?.cancel();
      positionSubscription?.cancel();
      positionSubscription = null;
      Storage.clearStorage(); // Clear files
      await Geolocator.getCurrentPosition();
      await Future.delayed(const Duration(milliseconds: 200));

      serviceInstance.stopSelf();
    });

    // Get current state
    getStateSubscription = serviceInstance.on(ServiceEvent.getState.name).listen((_) {
      final update = LocationUpdate(
        lat: 0.0,
        lng: 0.0,
        type: 'S',  // SYNC
        totalDistance: totalDistance,
        steps: steps,
        elevationGain: elevationGain,
        elevationLoss: elevationLoss,
        avgSpeed: avgSpeed,
        pace: pace,
        calories: calories,
        positionAccuracy: 0.0,
        trackingState: trackingState,
        trackedPath: trackedPath,
      );
      serviceInstance.invoke(ServiceEvent.sync.name, update.toJson());
    });

    // pause service
    pauseSubscription = serviceInstance.on(ServiceEvent.pause.name).listen((_) {
      trackingState = TrackingState.paused;

      final update = LocationUpdate(
        lat: 0.0,
        lng: 0.0,
        type: 'S', // sync
        totalDistance: totalDistance,
        steps: steps,
        elevationGain: elevationGain,
        elevationLoss: elevationLoss,
        avgSpeed: avgSpeed,
        pace: pace,
        calories: calories,
        positionAccuracy: 0.0,
        trackingState: trackingState,
        trackedPath: trackedPath,
      );
      serviceInstance.invoke(ServiceEvent.sync.name, update.toJson());
    });

    // resume service
    resumeSubscription = serviceInstance.on(ServiceEvent.resume.name).listen((_) {
     trackingState = TrackingState.running;
    });

    serviceInstance.invoke(ServiceEvent.ready.name);
  }

  // Elapsed time timer
  timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (trackingState == TrackingState.running) {
      elapsedTime += const Duration(seconds: 1);
    }
  });

  // location stream
  final locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1);
  positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
    currentPosition = LatLng(position.latitude, position.longitude);

    if (latestPosition != null && trackingState == TrackingState.running) {
      double distance = distanceCalculator.as(
        LengthUnit.Meter,
        LatLng(latestPosition!.latitude, latestPosition!.longitude),
        currentPosition!,
      );

      final elapsedSec = position.timestamp.difference(latestPosition!.timestamp).inMilliseconds / 1000.0;
      if (elapsedSec > 0) {
        currentSpeedValue = (distance / elapsedSec) * 3.6;
      }

      if(currentSpeedValue > maxHumanSpeed || position.accuracy > 30){
        print('jump');
          // Gps jump
      }else{
        totalDistance += distance;

        double deltaElevation = position.altitude - latestPosition!.altitude;
        if (deltaElevation > 0) elevationGain += deltaElevation;
        if (deltaElevation < 0) elevationLoss += deltaElevation.abs();

        steps = (totalDistance / averageStepLength).round();

        calories = 0.75 * weightKg * (totalDistance / 1000);
        if (totalDistance > 0) {
          pace = elapsedTime.inSeconds / 60 / (totalDistance / 1000);
        }
        avgSpeed = (totalDistance / 1000) / (elapsedTime.inSeconds / 3600);

        if (trackingState == TrackingState.running && (trackedPath.isEmpty || distanceCalculator.as(LengthUnit.Meter, trackedPath.last, currentPosition!) > 2)) {
          trackedPath.add(currentPosition!);
        }

      }
    }

    latestPosition = position;

    if(trackingState == TrackingState.running){
      final update = LocationUpdate(
        type: 'u',
        lat: currentPosition!.latitude,
        lng: currentPosition!.longitude,
        totalDistance: totalDistance,
        elevationGain: elevationGain,
        elevationLoss: elevationLoss,
        avgSpeed: avgSpeed,
        pace: pace,
        steps: steps,
        calories: calories,
        positionAccuracy: 0,
      );

      serviceInstance.invoke(ServiceEvent.update.name,update.toJson());
    }else{  // Update only gps accuracy
      final update = LocationUpdate(
        type: 'lu', // Location accuracy for gps
        lat: currentPosition!.latitude,
          lng: currentPosition!.longitude,
          totalDistance: totalDistance,
          positionAccuracy: latestPosition?.accuracy ?? 0,
        avgSpeed:  0,
        calories: 0,
        elevationGain: 0,
        elevationLoss: 0,
        pace: 0,
        steps: 0,
      );
      serviceInstance.invoke(ServiceEvent.update.name,update.toJson());

    }

    Storage.saveLocations(trackedPath);
    Storage.saveStats({
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime.inSeconds,
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'pace': pace,
      'steps': steps,
      'currentSpeedValue': currentSpeedValue,
    });
  });
}

class ForegroundTrackService {
  ForegroundTrackService._privateConstructor();

  static final ForegroundTrackService instance = ForegroundTrackService._privateConstructor();

  final FlutterBackgroundService service = FlutterBackgroundService();
  bool _initialized = false;

  @pragma('vm:entry-point')
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        initialNotificationTitle: "Tracking location",
        initialNotificationContent: "RunTracK tracks your activity!",
        foregroundServiceNotificationId: 911,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  Future<void> startTracking() async {
    await service.startService();

    final completer = Completer<void>();

    late StreamSubscription sub;
    sub = service.on('ready').listen((_) {
      completer.complete();
      sub.cancel();
    });

    await completer.future;

    service.invoke(ServiceEvent.startService.name);
  }


  Future<void> stopTracking() async {
    service.invoke(ServiceEvent.stopService.name);
  }

  Future<void> pauseTracking() async {
    service.invoke(ServiceEvent.pause.name);
  }

  Future<void> resumeTracking() async {
    service.invoke(ServiceEvent.resume.name);
  }

  Future<void> getState() async {
    service.invoke(ServiceEvent.getState.name);
  }
}
