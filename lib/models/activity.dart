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
  enums.Visibility visibility;
  List<String> photos;

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
    this.visibility = enums.Visibility.me,
    this.photos = const [],
    this.createdAt
  });

  Map<String, dynamic> toMap() {
    return {
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'trackedPath': trackedPath
          ?.map((latLng) =>
      {
        'lat': latLng.latitude.toDouble(),
        'lng': latLng.longitude.toDouble()
      })
          .toList(),
      'activityType': activityType,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'title': title,
      'description': description,
      'visibility': visibility,
      'photos': photos,
    };
  }

}
