import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/app/config/app_settings.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/enums/visibility.dart';
import 'package:run_track/core/models/activity.dart';
import '../../../../core/enums/tracking_state.dart' show TrackingState;
import '../models/storage.dart';
import 'package:run_track/features/settings/data/services/settings_service.dart';
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

  TrackingState trackingState = TrackingState.stopped;

  double userWeight = 0;
  int userHeight = 0;
  double currentStrideLength = 0.78;
  String userGender = "Male";

  List<LatLng> trackedPath = [];
  double totalDistance = 0.0;
  final Distance distanceCalculator = Distance();
  Position? latestPosition;
  Duration elapsedTime = Duration.zero;
  double elevationGain = 0.0;
  double elevationLoss = 0.0;
  double avgSpeed = 0.0;
  int steps = 0;
  double calories = 0.0;
  double pace = 0.0;
  LatLng? currentPosition;
  // Competition
  String currentCompetition = ""; // Current competition
  double distanceToGo = 10.0;
  Duration maxTimeToComplete = Duration.zero;

  // Settings
  int settingDistanceFilter = 15; // meters
  double settingMaxAccuracy = 30.0; // meters (GPS jump threshold)
  double settingMaxSpeedKmh = 43.0;
  LocationAccuracy settingAccuracyLevel = LocationAccuracy.best;

  DateTime? startTime;

  Timer? timeTimer;
  StreamSubscription<Position>? positionSubscription;

  // Counter to fetch error
  int ignoredPointsCount = 0;
  const int maxJumpsCount = 5;


  void recalculateStrideLength() {
    if (userHeight <= 0) {
      currentStrideLength = 0.78;
      return;
    }

    double genderFactor = (userGender == "Female") ? 0.413 : 0.415;
    double runFactor = 1.25;
    currentStrideLength = (userHeight * genderFactor * runFactor) / 100;
  }

  void clearStats() {
    totalDistance = 0.0;
    elevationGain = 0.0;
    elevationLoss = 0.0;
    userHeight = 0;
    userWeight = 0;
    calories = 0;
    avgSpeed = 0.0;
    pace = 0.0;
    steps = 0;
    elapsedTime = Duration.zero;
    trackedPath = [];
    currentPosition = null;
    latestPosition = null;
    trackingState = TrackingState.stopped;
    currentCompetition = "";
    distanceToGo = 0.0;
    maxTimeToComplete = Duration.zero;
  }

  void stopLocationTimerAndStream() {
    timeTimer?.cancel();
    timeTimer = null;
    positionSubscription?.cancel();
    positionSubscription = null;
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

  void stopService() async {
    sendSync("E"); // End sync

    // Save stats to local storage
    if (currentCompetition.isNotEmpty) {
      final activityData = Activity(
        activityId: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: "",
        activityType: "Competition activity",
        title: "Competition: $totalDistance",
        description: "",
        totalDistance: totalDistance,
        elapsedTime: elapsedTime.inSeconds,
        startTime: startTime ?? DateTime.now().subtract(elapsedTime),
        trackedPath: List.from(trackedPath),
        pace: pace,
        avgSpeed: avgSpeed,
        calories: calories,
        elevationGain: elevationGain,
        createdAt: DateTime.now(),
        steps: steps,
        visibility: ComVisibility.me,
      );
      try{
        await ActivityStorage.saveActivity(activityData);
      }catch(e){
        print("Error saving activity $e");
      }
    }

    stopLocationTimerAndStream();
    clearStats();

    serviceInstance.invoke(ServiceEvent.stopped.name);
    await Future.delayed(const Duration(milliseconds: 100));
    serviceInstance.stopSelf();
  }

  double getRunningMET(double speedKmh) {
    if (speedKmh < 7.0) return 6.0;
    if (speedKmh < 8.0) return 8.3;
    if (speedKmh < 9.5) return 9.8;
    if (speedKmh < 10.8) return 10.5;
    if (speedKmh < 11.5) return 11.0;
    if (speedKmh < 12.8) return 11.8;
    if (speedKmh < 14.5) return 12.8;
    if (speedKmh < 16.0) return 14.5;
    return 16.0;
  }

  void startLocationTimerAndStream() {
    if (positionSubscription != null) {
      positionSubscription!.cancel();
    }

    if (timeTimer == null) {
      startTime = DateTime.now().subtract(elapsedTime);
      timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (trackingState == TrackingState.running) {
          elapsedTime = DateTime.now().difference(startTime!);
        }
        // Check competition max time to complete activity
        if (currentCompetition.isNotEmpty && maxTimeToComplete.inSeconds > 0) {
          if (elapsedTime >= maxTimeToComplete) {
            trackingState = TrackingState.stopped;
            stopService();
            return;
          }
        }

      });
    }

    startTime = DateTime.now().subtract(elapsedTime);

    // location stream
    final locationSettings = LocationSettings(
      accuracy: settingAccuracyLevel,
      distanceFilter: settingDistanceFilter,
    );
    positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      if (position.latitude == 0.0 && position.longitude == 0.0) return;
      if (latestPosition == null) {
        latestPosition = position;
        return;
      }
      currentPosition = LatLng(position.latitude, position.longitude);

      if (trackingState == TrackingState.running) {
        double distance = distanceCalculator.as(
          LengthUnit.Meter,
          LatLng(latestPosition!.latitude, latestPosition!.longitude),
          currentPosition!,
        );

        final timeDifference = position.timestamp.difference(latestPosition!.timestamp).inSeconds;

        double calculatedSpeedKmh = 0.0;
        if (timeDifference > 0) {
          calculatedSpeedKmh = (distance / timeDifference) * 3.6; // m/s on km/h
        } else if (distance > 50) {
          // 0 s and big distance so for sure it is error
          calculatedSpeedKmh = 1000.0;
        }

        double positionSpeed = position.speed * 3.6;
        double speedToCheck = (calculatedSpeedKmh > positionSpeed) ? calculatedSpeedKmh : positionSpeed;

        bool isGpsJump = false;

        if (speedToCheck > settingMaxSpeedKmh) {
          isGpsJump = true;
        }

        if (position.accuracy > settingMaxAccuracy) {
          isGpsJump = true;
        }

        if (isGpsJump) {
          ignoredPointsCount++;
          if (ignoredPointsCount > maxJumpsCount) {
            // After max jumps count just add this position, it prevents deadlocks
            latestPosition = position;
            ignoredPointsCount = 0;
            
            trackedPath.add(currentPosition!);

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
          }
          return;
        } else {
          totalDistance += distance;

          double deltaElevation = position.altitude - latestPosition!.altitude;
          if (deltaElevation > 0) elevationGain += deltaElevation;
          if (deltaElevation < 0) elevationLoss += deltaElevation.abs();

          if (elapsedTime.inSeconds > 0) {
            avgSpeed = (totalDistance / 1000) / (elapsedTime.inSeconds / 3600);
          } else {
            avgSpeed = 0.0;
          }

          // Calories
          if (userWeight > 0 && elapsedTime.inSeconds > 0) {
            double currentMet = getRunningMET(avgSpeed);

            double hours = elapsedTime.inSeconds / 3600.0;
            //  Kcal = MET * weight * hours
            calories = currentMet * userWeight * hours;
          }

          // Steps
          if (currentStrideLength > 0) {
            steps = (totalDistance / currentStrideLength).round();
          } else {
            steps = (totalDistance / 0.78).round();
          }

          if (elapsedTime.inSeconds > 0 && totalDistance > 0) {
            pace = elapsedTime.inSeconds / 60 / (totalDistance / 1000);
          } else {
            pace = 0.0;
          }

          if (trackedPath.isEmpty ||
              distanceCalculator.as(LengthUnit.Meter, trackedPath.last, currentPosition!) > 2) {
            if (trackedPath.length >= 2) {
              LatLng pointA = trackedPath[trackedPath.length - 2];
              LatLng pointB = trackedPath.last;
              LatLng pointC = currentPosition!;

              // Calc bearing between point to avoid adding redundant positions in straight line
              double bearingBetweenAB = Geolocator.bearingBetween(
                pointA.latitude,
                pointA.longitude,
                pointB.latitude,
                pointB.longitude,
              );
              double bearingBetweenBC = Geolocator.bearingBetween(
                pointB.latitude,
                pointB.longitude,
                pointC.latitude,
                pointC.longitude,
              );

              double diff = (bearingBetweenAB - bearingBetweenBC).abs();
              if (diff > 180) {
                diff = 360 - diff;
              }

              double straightLineThreshold = 10.0;

              if (diff < straightLineThreshold) {
                trackedPath.last = pointC;
              } else {
                trackedPath.add(pointC);
              }
            } else {
              trackedPath.add(currentPosition!);
            }
          }
          latestPosition = position;
        }
        // Finish competition
        if (currentCompetition.isNotEmpty) {
          if (totalDistance >= distanceToGo) {
            trackingState = TrackingState.stopped;
            totalDistance = distanceToGo; // Set to have equal distance
            stopService();
          }
        }
      } else {
        latestPosition = position;
      }

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
    });
  }




  // Handle events from UI
  if (serviceInstance is AndroidServiceInstance) {
    // Start service
    serviceInstance.on(ServiceEvent.startService.name).listen((Map<String, dynamic>? data) {
      clearStats();
      if (data == null) return;
      if (data.containsKey('distanceFilter')) settingDistanceFilter = data['distanceFilter'];
      if (data.containsKey('maxAccuracy')) {
        settingMaxAccuracy = (data['maxAccuracy'] as num).toDouble();
      }
      if (data.containsKey('maxSpeed')) settingMaxSpeedKmh = (data['maxSpeed'] as num).toDouble();
      if (data.containsKey('accuracyLevel')) {
        settingAccuracyLevel = SettingsService.getAccuracyEnum(data['accuracyLevel']);
      }
      if (data.containsKey('userWeight')) userWeight = (data['userWeight'] as num).toDouble();
      if (data.containsKey('userHeight')) userHeight = (data['userHeight'] as num).toInt();
      if (data.containsKey('userGender')) userGender = data['userGender'] as String;
      recalculateStrideLength();

      currentCompetition = data['currentUserCompetition'] ?? "";
      distanceToGo = (data['distanceToGo'] as num?)?.toDouble() ?? 0.0;
      distanceToGo = distanceToGo * 1000; // Convert to meters
      int maxTimeToCompleteActivityMinutes = (data['maxTimeToCompleteActivityMinutes'] ?? 0)
          .toInt();
      int maxTimeToCompleteActivityHours = (data['maxTimeToCompleteActivityHours'] ?? 0).toInt();
      maxTimeToComplete = Duration(
        hours: maxTimeToCompleteActivityHours,
        minutes: maxTimeToCompleteActivityMinutes,
      );

      trackingState = TrackingState.running;
      startLocationTimerAndStream();
      serviceInstance.setAsForegroundService();
    });

    // Stop service
    serviceInstance.on(ServiceEvent.stopService.name).listen((_) async {
      stopService();
    });

    // Get current state
    serviceInstance.on(ServiceEvent.getState.name).listen((_) {
      sendSync("S");
    });

    // pause service
    serviceInstance.on(ServiceEvent.pause.name).listen((_) {
      trackingState = TrackingState.paused;
      sendSync("S");
    });

    // resume service
    serviceInstance.on(ServiceEvent.resume.name).listen((_) {
      startTime = DateTime.now().subtract(elapsedTime);
      trackingState = TrackingState.running;
    });

    Future.delayed(const Duration(seconds: 1), () {
      // Service is ready signal here
      serviceInstance.invoke(ServiceEvent.ready.name);
    });
  }
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
        await completer.future.timeout(const Duration(seconds: 8));
      } catch (e) {
        print("$e");
      }
    }

    await service.startService();

    final readyCompleter = Completer<void>();
    late StreamSubscription readySub;
    readySub = service.on(ServiceEvent.ready.name).listen((_) {
      readyCompleter.complete();
      readySub.cancel();
    });

    try {
      await readyCompleter.future.timeout(const Duration(seconds: 3));
    } catch (e) {
      print("Service start error $e");
    }

    int userHeight = AppData.instance.currentUser?.height ?? 0;
    double userWeight = AppData.instance.currentUser?.weight ?? 0.0;

    service.invoke(ServiceEvent.startService.name, {
      'currentUserCompetition': AppData.instance.currentUser?.currentCompetition,
      'distanceToGo': AppData.instance.currentUserCompetition?.distanceToGo ?? 0.0,
      'maxTimeToCompleteActivityHours':
          AppData.instance.currentUserCompetition?.maxTimeToCompleteActivityHours ?? 0,
      'maxTimeToCompleteActivityMinutes':
          AppData.instance.currentUserCompetition?.maxTimeToCompleteActivityMinutes ?? 0,
      'distanceFilter': AppSettings.instance.gpsDistanceFilter ?? AppConstants.gpsDistanceFilter,
      'maxAccuracy': AppSettings.instance.gpsMinAccuracy ?? AppConstants.gpsMinAccuracy,
      'maxSpeed':
          AppSettings.instance.gpsMaxSpeedToDetectJumps ?? AppConstants.gpsMaxSpeedToDetectJumps,
      'accuracyLevel': SettingsService.accuracyEnumToString(
        AppSettings.instance.gpsAccuracyLevel ?? AppConstants.locationAccuracy,
      ),
      'userWeight': userWeight,
      'userHeight': userHeight,
      'userGender': AppData.instance.currentUser?.gender ?? "Male",
    });
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
