import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Activity {
  double? totalDistance;
  int? elapsedTime;
  List<LatLng>? trackedPath;
  final String? activityType;
  final DateTime? createdAt;
  final DateTime? startTime;
  String? title;
  String? description;
  String? visibility;
  List<String> photos;

  Activity({
    this.totalDistance,
    this.elapsedTime,
    this.trackedPath,
    this.activityType,
    this.startTime,
    this.title,
    this.description,
    this.visibility,
    this.photos = const [],
    this.createdAt
  });

  Map<String, dynamic> toMap() {
    return {
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'trackedPath': trackedPath
          ?.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude})
          .toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'startTime': startTime,
      'title': title,
      'description': description,
      'visibility': visibility,
      'photos': photos,
    };
  }

  // Convert Firestore data -> Activity
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      totalDistance: map['totalDistance']?.toDouble(),
      elapsedTime: map['elapsedTime'], // already stored as int
      trackedPath: (map['trackedPath'] as List?)
          ?.map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      activityType: map['activityType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      title: map['title'],
      description: map['description'],
      visibility: map['visibility'],
      photos: List<String>.from(map['photos'] ?? []),
    );
  }
}

