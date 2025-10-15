import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/visibility.dart' as enums;

class Activity {
  String activityId; // Activity id
  String uid; // User id
  double? totalDistance;
  int? elapsedTime;
  List<LatLng>? trackedPath;
  final String? activityType;
  final DateTime? createdAt;
  final DateTime? startTime;
  String? title;
  String? description;
  enums.ComVisibility visibility;
  List<String> photos;

  double? calories;
  double? avgSpeed; // km/h
  double? elevationGain; // m
  int? steps;
  double? pace;

  Activity({
    this.activityId = "",
    required this.uid,
    this.totalDistance,
    this.elapsedTime,
    this.trackedPath,
    this.activityType,
    this.startTime,
    this.title,
    this.description,
    this.visibility = enums.ComVisibility.me,
    this.photos = const [],
    this.createdAt,
    this.calories,
    this.avgSpeed,
    this.elevationGain,
    this.steps,
    this.pace
  });

}
