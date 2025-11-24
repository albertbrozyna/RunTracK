import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_data.dart';

import '../../../../core/enums/tracking_state.dart';
import '../../../../core/utils/utils.dart';
import '../services/track_foreground_service.dart';
import 'location_update.dart';

class TrackState extends ChangeNotifier {
  TrackState._privateConstructor() {
    _listenToBackgroundService();
    initialize();
  }

  static final TrackState trackStateInstance = TrackState._privateConstructor();

  TrackingState trackingState = TrackingState.stopped;
  List<LatLng> trackedPath = [];
  double totalDistance = 0.0;
  Position? latestPosition;
  DateTime? startTime;
  Duration elapsedTime = Duration.zero;
  double? elevationGain;
  double? elevationLoss;
  bool endSync = false;
  double? calories;
  double? avgSpeed;
  double? currentSpeedValue;
  int? steps;
  double? pace;
  bool followUser = true;
  LatLng? currentPosition;
  String currentUserCompetition = "";

  // gps icon to indicate gps signal
  Icon gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
  MapController? mapController;

  double positionAccuracy = 0;
  bool clearFields = false;
  Timer? _secondTimer; // Second timer
  DateTime _lastUpdateFromTask = DateTime.fromMillisecondsSinceEpoch(0);
  int fetchCounter = 0; // Counter that counts to fetch gps signal once at 5s
  bool _isFetchingLocation = false;

  bool isFinishing = false; // We are finishing run
  final double averageStepLength = 0.78; // Avg steps length

  bool _isStarting = false;

  void startRun(BuildContext context) async {
    try {
      if (_isStarting == true || trackingState == TrackingState.running || isFinishing) {
        return;
      }
      Position? pos = await checkPermissions(context);
      _isStarting = true;
      clearAllFields();
      if (pos != null) {
        currentPosition = LatLng(pos.latitude, pos.longitude);
        positionAccuracy = pos.accuracy;
        await ForegroundTrackService.instance.startTracking();
        trackingState = TrackingState.running;
        currentUserCompetition = AppData.instance.currentUserCompetition?.competitionId ?? '';
        notifyListeners();
      }
    } catch (e) {
      print("$e");
    } finally {
      _isStarting = false;
    }
  }

  bool _isPausing = false;

  void pauseRun() async {
    try {
      if (_isPausing == true || isFinishing) {
        return;
      }
      _isPausing = true;
      await ForegroundTrackService.instance.pauseTracking();
      trackingState = TrackingState.paused;
      notifyListeners();
    } catch (e) {
      print("$e");
    } finally {
      _isPausing = false;
    }
  }

  Completer<void>? _stopCompleter;

  Future<void> stopRun() async {
    if(isFinishing){
      return;
    }
    isFinishing = true;
    endSync = false;
    notifyListeners();
    try {
      _stopCompleter = Completer<void>();

      await ForegroundTrackService.instance.stopTracking();

      try {
        await _stopCompleter!.future.timeout(const Duration(seconds: 15));
      } catch (e) {
        endSync = true;
      } finally {
        trackingState = TrackingState.stopped;
        notifyListeners();
      }
    } catch (e) {
      print("Stop run error: $e");
      endSync = true;
      isFinishing = false;
      notifyListeners();
    }
  }

  void refreshUi() {
    notifyListeners();
  }

  void resumeRun() async {
    ForegroundTrackService.instance.resumeTracking();
    trackingState = TrackingState.running;
    notifyListeners();
  }

  // Create listeners for background
  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();

    // On update
    service.on(ServiceEvent.update.name).listen((event) {
      if (event != null) {
        final update = LocationUpdate.fromJson(event);

        if (update.type == 'u') {
          // Update new data
          totalDistance = update.totalDistance;
          elevationGain = update.elevationGain;
          elevationLoss = update.elevationLoss;
          calories = update.calories;
          avgSpeed = update.avgSpeed;
          pace = update.pace;
          steps = update.steps;
          LatLng lastLocation = LatLng(update.lat, update.lng);
          currentPosition = lastLocation;
          trackedPath.add(lastLocation);
          if (mapController != null && followUser) {
            // Move map
            mapController?.move(lastLocation, mapController?.camera.zoom ?? 15.0);
          }

          positionAccuracy = update.positionAccuracy;
          updateGpsIcon();
        } else if (update.type == 'lu') {
          // Only location update
          positionAccuracy = update.positionAccuracy;
          updateGpsIcon();

          LatLng lastLocation = LatLng(update.lat, update.lng);
          currentPosition = lastLocation;

          if (mapController != null && followUser) {
            // Move map
            mapController?.move(lastLocation, mapController?.camera.zoom ?? 15.0);
          }
        }

        _lastUpdateFromTask = DateTime.now();
        notifyListeners();
      }
    });

    // Sync data
    service.on(ServiceEvent.sync.name).listen((event) {
      print("nowy event jest");
      if (event != null) {
        print("nowy sync jest");
        final update = LocationUpdate.fromJson(event);
        currentUserCompetition = update.currentUserCompetition ?? '';
        trackingState = update.trackingState ?? TrackingState.stopped;
        totalDistance = update.totalDistance;
        elevationGain = update.elevationGain;
        elevationLoss = update.elevationLoss;
        calories = update.calories;
        elapsedTime = update.elapsedTime ?? Duration.zero;
        avgSpeed = update.avgSpeed;
        pace = update.pace;
        steps = update.steps;
        trackedPath = update.trackedPath ?? [];
        if (update.trackedPath != null && update.trackedPath!.isNotEmpty) {
          currentPosition = update.trackedPath?.last;
        }
        _lastUpdateFromTask = DateTime.now();
        if (update.type == 'E') {
          endSync = true;
          // Finish completer
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.complete();
          }
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _secondTimer?.cancel();
    _secondTimer = null;
  }

  void initialize() async {
    _secondTimer?.cancel(); // Timer to fetch check a gps signal if service is off
    _secondTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (trackingState == TrackingState.running) {
        elapsedTime += const Duration(seconds: 1); // Add seconds here to make timer smooth
      }
      //print("timerMain ${elapsedTime.inSeconds}");
      notifyListeners();
      final now = DateTime.now();
      if (now.difference(_lastUpdateFromTask) > Duration(seconds: 6)) {
        // If there is no signal from background service
        _fetchLocation(); // Get gps location
      }
    });
    ForegroundTrackService.instance.getState(); // Get state
  }

  Future<void> _fetchLocation() async {
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
      );

      latestPosition = position;
      currentPosition = LatLng(position.latitude, position.longitude);
      positionAccuracy = position.accuracy;

      if (followUser && mapController != null) {
        mapController?.move(
          LatLng(latestPosition!.latitude, latestPosition!.longitude),
          mapController?.camera.zoom ?? 15,
        );
      }

      updateGpsIcon(); // Update gps
      notifyListeners();
    } catch (e) {
      print('GPS error: $e');
    } finally {
      _isFetchingLocation = false;
    }
  }

  void updateGpsIcon() async {
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      gpsIcon = Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);
      return;
    }
    if (positionAccuracy <= 5) {
      gpsIcon = Icon(Icons.signal_cellular_alt, size: 24, color: Colors.green);
    } else if (positionAccuracy <= 15) {
      gpsIcon = Icon(Icons.signal_cellular_alt_2_bar_sharp, size: 24, color: Colors.orange);
    } else if (positionAccuracy <= 25) {
      gpsIcon = Icon(Icons.signal_cellular_alt_1_bar_sharp, size: 24, color: Colors.red);
    } else {
      gpsIcon = Icon(Icons.signal_cellular_0_bar, color: Colors.redAccent, size: 24);
    }
  }

  void clearAllFields({bool notify = false}) {
    trackedPath.clear();
    totalDistance = 0.0;
    startTime = DateTime.now();
    elapsedTime = Duration.zero;
    latestPosition = null;
    elevationGain = 0.0;
    elevationLoss = 0.0;
    calories = 0.0;
    avgSpeed = 0.0;
    currentSpeedValue = 0.0;
    steps = 0;
    pace = 0.0;
    followUser = true;
    currentPosition = null;
    trackingState = TrackingState.stopped;
    positionAccuracy = 0;
    _isFetchingLocation = false;
    _lastUpdateFromTask = DateTime.now();
    currentUserCompetition = "";

    gpsIcon = const Icon(Icons.signal_cellular_off, color: Colors.grey, size: 24);

    // Invoke it conditionally
    if (notify) {
      notifyListeners();
    }
  }

  static Future<Position?> checkPermissions(BuildContext context) async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied. Enable them in settings.");
      }

      // Check GPS is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled. Enable GPS.");
      }

      // Get location
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10),
      );
    } catch (e) {
      AppUtils.showMessage(context, e.toString());
      return null;
    }
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
}
