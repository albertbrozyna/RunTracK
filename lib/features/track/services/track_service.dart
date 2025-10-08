import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TrackService {


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