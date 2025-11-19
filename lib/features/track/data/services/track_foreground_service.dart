import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_data.dart';
import '../../../../core/enums/tracking_state.dart' show TrackingState;
import '../models/storage.dart';

import '../models/location_update.dart';

enum ServiceEvent {
  startService,
  stopService,
  update,
  pause,
  resume,
  getState,
  sync,
  ready,
  stopped,
}

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
  // Competition
  String currentCompetition = ""; // Current competition
  double distanceToGo = 10.0;
  Duration maxTimeToComplete = Duration.zero;

  Timer? timeTimer;
  StreamSubscription<Position>? positionSubscription;

  void clearStats() {
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
    currentCompetition = "";
    distanceToGo = 0.0;
    maxTimeToComplete = Duration.zero;
    Storage.clearStorage();
  }

  void stopLocationTimerAndStream() {
    timeTimer?.cancel();
    timeTimer = null;
    positionSubscription?.cancel();
    positionSubscription = null;
    print("Serwis: Zatrzymano timer i strumień lokalizacji.");
  }

  // try {
  //   final stats = await Storage.loadStats();
  //   final savedLocations = await Storage.loadLocations();
  //
  //   if (stats.isNotEmpty) {
  //     print("znaleziono stare pliki");
  //     totalDistance = (stats['totalDistance'] ?? 0.0).toDouble();
  //     elevationGain = (stats['elevationGain'] ?? 0.0).toDouble();
  //     elevationLoss = (stats['elevationLoss'] ?? 0.0).toDouble();
  //     calories = (stats['calories'] ?? 0.0).toDouble();
  //     avgSpeed = (stats['avgSpeed'] ?? 0.0).toDouble();
  //     pace = (stats['pace'] ?? 0.0).toDouble();
  //     steps = (stats['steps'] ?? 0).toInt();
  //     currentSpeedValue = (stats['currentSpeedValue'] ?? 0.0).toDouble();
  //     elapsedTime = Duration(seconds: (stats['elapsedTime'] ?? 0).toInt());
  //     currentCompetition = stats['currentCompetition'];
  //
  //     // Read saved state
  //     final savedState = stats['trackingState'] as String?;
  //     if (savedState == 'running') {
  //       trackingState = TrackingState.running;
  //     } else if (savedState == 'paused') {
  //       trackingState = TrackingState.paused;
  //     } else {
  //       trackingState = TrackingState.stopped;
  //       print("zatrzymany");
  //     }
  //   }
  //
  //   if (savedLocations.isNotEmpty) {
  //     trackedPath = savedLocations;
  //     currentPosition = savedLocations.last;
  //     print("lokalizacje tez");
  //   }
  // } catch (e) {}

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
    final locationSettings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 15);
    positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
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

        if (currentSpeedValue > maxHumanSpeed || position.accuracy > 30) {
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
              (trackedPath.isEmpty ||
                  distanceCalculator.as(LengthUnit.Meter, trackedPath.last, currentPosition!) >
                      2)) {
            trackedPath.add(currentPosition!);
            print("MYLOG added");
          }

          // Finish competition
          if (currentCompetition.isNotEmpty) {
            if (totalDistance >= distanceToGo || elapsedTime >= maxTimeToComplete) {
              serviceInstance.invoke(ServiceEvent.stopService.name);
            }
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

      // saveCounter++;
      // if (saveCounter % 10 == 0) {
      //   Storage.saveLocations(trackedPath);
      //   Storage.saveStats({
      //     'totalDistance': totalDistance,
      //     'elapsedTime': elapsedTime.inSeconds,
      //     'elevationGain': elevationGain,
      //     'elevationLoss': elevationLoss,
      //     'calories': calories,
      //     'avgSpeed': avgSpeed,
      //     'pace': pace,
      //     'steps': steps,
      //     'currentSpeedValue': currentSpeedValue,
      //     'trackingState': trackingState.name,
      //     'currentCompetition': currentCompetition,
      //   });
      // }
    });
  }

  void sendSync(String type) {
    final update = LocationUpdate(
      lat: 0.0,
      lng: 0.0,
      type: type,
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
      currentUserCompetition: currentCompetition,
    );
    serviceInstance.invoke(ServiceEvent.sync.name, update.toJson());
  }

  // Handle events from UI
  if (serviceInstance is AndroidServiceInstance) {
    // Start service
    serviceInstance.on(ServiceEvent.startService.name).listen((Map<String, dynamic>? data) {
      clearStats();
      currentCompetition = data?['currentUserCompetition'] ?? "";
      distanceToGo = data?['distanceToGo'] ?? 0.0;
      int maxTimeToCompleteActivityMinutes = data?['maxTimeToCompleteActivityMinutes'];
      int maxTimeToCompleteActivityHours = data?['maxTimeToCompleteActivityHours'];
      maxTimeToComplete = Duration(
        hours: maxTimeToCompleteActivityHours,
        minutes: maxTimeToCompleteActivityMinutes,
      );
      trackingState = TrackingState.running;
      startLocationTimerAndStream();
      print("MYLOG start");
      serviceInstance.setAsForegroundService();
    });

    // Stop service
    serviceInstance.on(ServiceEvent.stopService.name).listen((_) async {
      sendSync("E"); // End sync
      stopLocationTimerAndStream();
      clearStats();

      print("MYLOG stop here - Wysyłam 'stopped' i niszczę serwis.");

      serviceInstance.invoke(ServiceEvent.stopped.name);

      await Future.delayed(const Duration(milliseconds: 100));

      serviceInstance.stopSelf();
    });

    // Get current state
    serviceInstance.on(ServiceEvent.getState.name).listen((_) {
      sendSync("S");
    });

    // pause service
    serviceInstance.on(ServiceEvent.pause.name).listen((_) {
      print("MYLOG pause");
      trackingState = TrackingState.paused;
      sendSync("S");
    });

    // resume service
    serviceInstance.on(ServiceEvent.resume.name).listen((_) {
      print("MYLOG res");
      trackingState = TrackingState.running;
    });

    Future.delayed(const Duration(seconds: 1), () {
      // Service is ready signal here
      serviceInstance.invoke(ServiceEvent.ready.name);
    });
  }

  // // Start run if state is different from stopped
  // if (trackingState != TrackingState.stopped) {
  //   print("MYLOG auto start");
  //   startLocationTimerAndStream();
  //   if (serviceInstance is AndroidServiceInstance) {
  //     serviceInstance.setAsForegroundService();
  //   }
  // }

  print("MYLOG test nowy kodV4");
}

class ForegroundTrackService {
  ForegroundTrackService._privateConstructor();

  static final ForegroundTrackService instance = ForegroundTrackService._privateConstructor();

  final FlutterBackgroundService service = FlutterBackgroundService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        initialNotificationTitle: "Tracking location",
        initialNotificationContent: "RunTracK tracks your activity!",
        foregroundServiceNotificationId: 911,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  Future<void> startTracking() async {
    if (await service.isRunning()) {
      print("MYLOG Poprzedni serwis działa. Zatrzymuję go...");

      final completer = Completer<void>();
      late StreamSubscription sub;
      sub = service.on(ServiceEvent.stopped.name).listen((_) {
        print("MYLOG Otrzymano sygnał 'stopped' od starego serwisu.");
        completer.complete();
        sub.cancel();
      });

      service.invoke(ServiceEvent.stopService.name);

      try {
        await completer.future.timeout(const Duration(seconds: 4));
      } catch (e) {}
    }

    await service.startService();
    print("MYLOG Nowy serwis uruchomiony.");

    final readyCompleter = Completer<void>();
    late StreamSubscription readySub;
    readySub = service.on(ServiceEvent.ready.name).listen((_) {
      print("MYLOG Nowy serwis jest gotowy.");
      readyCompleter.complete();
      readySub.cancel();
    });

    try {
      await readyCompleter.future.timeout(const Duration(seconds: 3));
    } catch (e) {
      print("MYLOG Nowy serwis nie zgłosił gotowości na czas.");
    }

    service.invoke(ServiceEvent.startService.name, {
      'currentUserCompetition': AppData.instance.currentUser?.currentCompetition,
      'distanceToGo': AppData.instance.currentUserCompetition?.distanceToGo ?? 0.0,
      'maxTimeToCompleteActivityHours':
          AppData.instance.currentUserCompetition?.maxTimeToCompleteActivityHours ?? 0.0,
      'maxTimeToCompleteActivityMinutes':
          AppData.instance.currentUserCompetition?.maxTimeToCompleteActivityMinutes ?? 0.0,
    });
    print("MYLOG after start in ui side");
  }

  Future<void> stopTracking() async {
    if (await service.isRunning()) {
      service.invoke(ServiceEvent.stopService.name);
    }
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
