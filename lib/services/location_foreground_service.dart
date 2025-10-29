import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/permission_utils.dart';

class LocationTaskHandler extends TaskHandler {
  List<LatLng> track = [];
  bool granted = true;

  void saveToFile(){

  }

  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }


  @override
  Future<void> onStart(DateTime timestamp,TaskStarter starter) async {
    granted = await checkPermissions();
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
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high
        ),
      );
      track.add(LatLng(position.longitude, position.latitude));
      FlutterForegroundTask.sendDataToMain({
        'lat': position.latitude,
        'lng': position.longitude,
      });
    } catch (e) {
      print("Błąd pobierania lokalizacji: $e");
    }
  }
}
