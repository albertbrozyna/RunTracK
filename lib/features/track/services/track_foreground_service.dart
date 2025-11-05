import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../common/enums/tracking_state.dart';
import '../models/storage.dart';

import '../models/location_update.dart';

enum ServiceEvent { startService, stopService, update, pause, resume, getState, sync, ready, stopped }

@pragma('vm:entry-point')
void onStart(ServiceInstance serviceInstance) async {
  DartPluginRegistrant.ensureInitialized();


  print("MYLOG new serwice v1");
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
  int saveCounter = 0;

  Timer? timeTimer;
  StreamSubscription<Position>? positionSubscription;

  void clearStats(){
    totalDistance = 0.0;
    elevationGain = 0.0;
    elevationLoss = 0.0;
    calories = 0.0;
    avgSpeed = 0.0;
    pace = 0.0;
    steps = 0;
    currentSpeedValue = 0.0;
    elapsedTime = Duration.zero;
    trackedPath = [];
    currentPosition = null;
    latestPosition = null;
    trackingState = TrackingState.stopped;
    saveCounter = 0;
    Storage.clearStorage();
  }

  void stopLocationTimerAndStream() {
    timeTimer?.cancel();
    timeTimer = null;
    positionSubscription?.cancel();
    positionSubscription = null;
    print("Serwis: Zatrzymano timer i strumień lokalizacji.");
  }

  try {
    final stats = await Storage.loadStats();
    final savedLocations = await Storage.loadLocations();

    if (stats.isNotEmpty) {
      print("znaleziono stare pliki");
      totalDistance = (stats['totalDistance'] ?? 0.0).toDouble();
      elevationGain = (stats['elevationGain'] ?? 0.0).toDouble();
      elevationLoss = (stats['elevationLoss'] ?? 0.0).toDouble();
      calories = (stats['calories'] ?? 0.0).toDouble();
      avgSpeed = (stats['avgSpeed'] ?? 0.0).toDouble();
      pace = (stats['pace'] ?? 0.0).toDouble();
      steps = (stats['steps'] ?? 0).toInt();
      currentSpeedValue = (stats['currentSpeedValue'] ?? 0.0).toDouble();
      elapsedTime = Duration(seconds: (stats['elapsedTime'] ?? 0).toInt());

      // Read saved state
      final savedState = stats['trackingState'] as String?;
      if (savedState == 'running') {
        trackingState = TrackingState.running;
      } else if (savedState == 'paused') {
        trackingState = TrackingState.paused;
      } else {
        trackingState = TrackingState.stopped;
        print("zatrzymany");
      }
    }

    if (savedLocations.isNotEmpty) {
      trackedPath = savedLocations;
      currentPosition = savedLocations.last;
      print("lokalizacje tez");
    }
  } catch (e) {}


  void startLocationTimerAndStream() {
    if (positionSubscription != null || timeTimer != null) return;

    print("MYLOG Serwis: Uruchomiono timer i strumień lokalizacji.");

    // Elapsed time timer
    timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (trackingState == TrackingState.running) {
        elapsedTime += const Duration(seconds: 1);
      }
    });

    // location stream
    final locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3);
    positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (position.latitude == 0.0 && position.longitude == 0.0) return;
      if (latestPosition == null) {
        latestPosition = position;
        return;
      }

      currentPosition = LatLng(position.latitude, position.longitude);

      print("MYLOG new position");
      if (latestPosition != null && trackingState == TrackingState.running) {
        double distance = distanceCalculator.as(
          LengthUnit.Meter,
          LatLng(latestPosition!.latitude, latestPosition!.longitude),
          currentPosition!,
        );

        currentSpeedValue = position.speed * 3.6;

        // TODO CAN BE || position.accuracy > 30
        if (currentSpeedValue > maxHumanSpeed ) {
          print('MYLOG jump');
          // Gps jump
        } else {
          totalDistance += distance;

          double deltaElevation = position.altitude - latestPosition!.altitude;
          if (deltaElevation > 0) elevationGain += deltaElevation;
          if (deltaElevation < 0) elevationLoss += deltaElevation.abs();

          steps = (totalDistance / averageStepLength).round();

          calories = 0.75 * weightKg * (totalDistance / 1000);
          if (elapsedTime.inSeconds > 0) {
            avgSpeed = (totalDistance / 1000) / (elapsedTime.inSeconds / 3600);
          } else {
            avgSpeed = 0.0;
          }

          if (elapsedTime.inSeconds > 0 && totalDistance > 0) {
            pace = elapsedTime.inSeconds / 60 / (totalDistance / 1000);
          } else {
            pace = 0.0;
          }

          if (trackingState == TrackingState.running &&
              (trackedPath.isEmpty || distanceCalculator.as(LengthUnit.Meter, trackedPath.last, currentPosition!) > 2)) {
            trackedPath.add(currentPosition!);
            print("MYLOG added");
          }
        }
        print('MYLOG location');
      }

      latestPosition = position;


      if (trackingState == TrackingState.running) {
        final update = LocationUpdate(
          type: 'u',
          lat: currentPosition!.latitude,
          lng: currentPosition!.longitude,
          totalDistance: totalDistance,
          elapsedTime: elapsedTime,
          elevationGain: elevationGain,
          elevationLoss: elevationLoss,
          avgSpeed: avgSpeed,
          pace: pace,
          steps: steps,
          calories: calories,
          positionAccuracy: position.accuracy,
        );
        serviceInstance.invoke(ServiceEvent.update.name, update.toJson());
      } else {
        // Update only gps accuracy
        final update = LocationUpdate(
          type: 'lu',
          lat: currentPosition!.latitude,
          lng: currentPosition!.longitude,
          totalDistance: totalDistance,
          positionAccuracy: latestPosition?.accuracy ?? 0,
          avgSpeed: 0,
          calories: 0,
          elevationGain: 0,
          elevationLoss: 0,
          pace: 0,
          steps: 0,
        );
        serviceInstance.invoke(ServiceEvent.update.name, update.toJson());
      }

      saveCounter++;
      if (saveCounter % 10 == 0) {
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
          'trackingState': trackingState.name,
        });
      }
    });
  }

  void sendSync(){
    final update = LocationUpdate(
      lat: 0.0,
      lng: 0.0,
      type: 'S',
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
      elapsedTime: elapsedTime,
    );
    serviceInstance.invoke(ServiceEvent.sync.name, update.toJson());
  }

  // Handle events from UI
  if (serviceInstance is AndroidServiceInstance) {
    // Start service
      serviceInstance.on(ServiceEvent.startService.name).listen((_) {
        clearStats();
      trackingState = TrackingState.running;
      startLocationTimerAndStream();
      print("MYLOG start");
        serviceInstance.setAsForegroundService();
      });

    // Stop service
     serviceInstance.on(ServiceEvent.stopService.name).listen((_) async {
      final update = LocationUpdate(
        lat: 0.0,
        lng: 0.0,
        type: 'e',
        // END
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
        elapsedTime: elapsedTime
      );
      serviceInstance.invoke(ServiceEvent.sync.name, update.toJson()); // Send sync flag
      stopLocationTimerAndStream();
      clearStats();

      print("MYLOG stop here");
      serviceInstance.invoke(ServiceEvent.stopped.name);
      serviceInstance.setAsBackgroundService();
    });

    // Get current state
     serviceInstance.on(ServiceEvent.getState.name).listen((_) {
       sendSync();
     });

    // pause service
    serviceInstance.on(ServiceEvent.pause.name).listen((_) {
      print("MYLOG pause");
      trackingState = TrackingState.paused;
      sendSync();
    });

    // resume service
     serviceInstance.on(ServiceEvent.resume.name).listen((_) {
       print("MYLOG res");
       trackingState = TrackingState.running;
    });

    Future.delayed(const Duration(seconds: 1), () {  // Service is ready signal here
      serviceInstance.invoke(ServiceEvent.ready.name);
    });
  }

  // Start run if state is different from stopped
  if (trackingState != TrackingState.stopped) {
    print("MYLOG auto start");
    startLocationTimerAndStream();
  }

  print("MYLOG test nowy kod");
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
        isForegroundMode: false,
        initialNotificationTitle: "Tracking location",
        initialNotificationContent: "RunTracK tracks your activity!",
        foregroundServiceNotificationId: 911,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  Future<void> startTracking() async {
    if (!await service.isRunning()) { // if doesnt work
      await service.startService();
      print("MYLOG New service started");

      final completer = Completer<void>();

      late StreamSubscription sub;
      sub = service.on(ServiceEvent.ready.name).listen((_) {
        completer.complete();
        sub.cancel();
      });
      await completer.future;
    }


    service.invoke(ServiceEvent.startService.name);
    print("MYLOG after start in ui side");
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
