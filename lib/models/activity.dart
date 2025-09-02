import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';

class Activity {
  double? totalDistance;
  Duration? elapsedTime;
  List<LatLng>? trackedPath;
  final String? activityType;
  final DateTime? startTime;
  String? title;
  String? description;
  Visibility? visibility;

  Activity(
    this.totalDistance,
    this.elapsedTime,
    this.trackedPath,
    this.activityType,
    this.startTime,
    this.title,
    this.description,
    this.visibility,
  );
}
