import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/features/track/models/storage.dart';

enum ServiceEvent {
  update,
  stopService,
}

/// Get string enum
extension ServiceEventExtension on ServiceEvent {
  String get name {
    return toString().split('.').last;
  }
}

class ForegroundTrackService {
  ForegroundTrackService._privateConstructor();
  static final ForegroundTrackService instance = ForegroundTrackService._privateConstructor();

  final FlutterBackgroundService service = FlutterBackgroundService();

  bool _initialized = false;

  // Tracking variables
  final double averageStepLength = 0.78;
  final double weightKg = 70;

  List<LatLng> trackedPath = [];
  double totalDistance = 0.0;
  final Distance distanceCalculator = Distance(); // To calc distance
  Position? latestPosition;
  DateTime? startTime;
  Duration elapsedTime = Duration.zero;
  double elevationGain = 0.0;
  double elevationLoss = 0.0;
  double calories = 0.0;
  double avgSpeed = 0.0;
  double currentSpeedValue = 0.0;
  int steps = 0;
  double pace = 0.0;
  LatLng? currentPosition;

  Timer? _timeTimer;
  Timer? _locationTimer;

  void _startTimers() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime += const Duration(seconds: 1);
      print("Czas: ${elapsedTime.inSeconds} s");
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
        );

        currentPosition = LatLng(position.latitude, position.longitude);

        if(latestPosition != null) {
          double distance = distanceCalculator.as(LengthUnit.Meter, LatLng(latestPosition!.latitude, latestPosition!.longitude), currentPosition!);
          totalDistance += distance;
          // Elevation gain
          double deltaElevation = position.altitude - latestPosition!.altitude;
          if (deltaElevation > 0) {
            elevationGain += deltaElevation;
          }
          if (deltaElevation < 0) {
            elevationLoss += deltaElevation.abs();
          }

          steps = (totalDistance / averageStepLength).round();


          // Current speed
          currentSpeedValue = distance / 5;

          // Calories
          calories = 0.75 * weightKg * (totalDistance / 1000);

          // Pace
          if (totalDistance > 0) {
            pace = elapsedTime.inSeconds / 60 / (totalDistance / 1000);
          }
        }
        latestPosition = position;


        if(trackedPath.isEmpty || distanceCalculator.as(LengthUnit.Meter,trackedPath.last ,currentPosition!) > 2){
          trackedPath.add(currentPosition!);
        }


        service.invoke(ServiceEvent.update.name, {
          'lat': position.latitude,
          'lng': position.longitude,
        });



        Storage.saveLocations(trackedPath); // Save locations to file
        Storage.saveStats({
          'totalDistance':totalDistance,
          'elapsedTime':elapsedTime.inSeconds,
          'elevationGain':elevationGain,
          'elevationLoss':elevationLoss,
          'calories':calories,
          'avgSpeed':avgSpeed,
          'pace':pace,
          'steps':steps,
          'currentSpeedValue':currentSpeedValue,
        });
        print("Lokacja: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("Błąd pobierania lokalizacji: $e");
      }
    });
  }


  void stopTimers(){
    _timeTimer?.cancel();
    _locationTimer?.cancel();
  }


  /// Initialize service
  @pragma('vm:entry-point')
  Future<void> init() async {
    if (_initialized) {
      return;
    }
      _initialized = true;

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          isForegroundMode: true,
          autoStart: false, // Start after pressed on start
          initialNotificationTitle: "Tracking location",
          initialNotificationContent: "RunTracK tracks your activity!",
          foregroundServiceNotificationId: 911,
        ),
        iosConfiguration: IosConfiguration(),
      );
    }

  @pragma('vm:entry-point')
  void _onStart(ServiceInstance serviceInstance) async {
    if (serviceInstance is AndroidServiceInstance) {
      serviceInstance.on(ServiceEvent.stopService.name).listen((event) {
        serviceInstance.stopSelf();
      });
    }

      _startTimers();



  }

  void clearStats(){
    trackedPath.clear();
    totalDistance = 0.0;
    calories = 0.0;
    avgSpeed = 0.0;
    elevationGain = 0.0;
    elevationLoss = 0.0;
    pace = 0.0;
    currentSpeedValue = 0.0;
  }

  Future<void> startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      print("Location service is disabled");
      return;
    }

    await service.startService();
    print("Background tracking started");
  }

  void stopTracking() {
    service.invoke(ServiceEvent.stopService.name);
    print("Background tracking stopped");
  }
}
