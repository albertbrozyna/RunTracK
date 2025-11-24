import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../enums/visibility.dart' as enums;
import '../utils/utils.dart';


class Activity {
  String activityId; // Activity id
  String uid; // User id
  double? totalDistance;
  int? elapsedTime;
  List<LatLng>? trackedPath;
  String? activityType;
  final DateTime? createdAt;
  final DateTime? startTime;
  String? title;
  String? description;
  enums.ComVisibility visibility;
  List<String> photos;
  double? calories;
  double? avgSpeed; // km/h
  double? elevationGain; // m
  double? elevationLoss; // m
  int? steps;
  double? pace;
  String competitionId = "";

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
    this.elevationLoss,
    this.steps,
    this.pace,
    this.competitionId = ""
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    final visibilityString = map['visibility'] as String?;
    final visibility = enums.ComVisibility.values.firstWhere(
          (e) => e.name == visibilityString,
      orElse: () => enums.ComVisibility.me,
    );

    return Activity(
      activityId: map['activityId'] ?? '',
      uid: map['uid'] ?? '',
      totalDistance: map['totalDistance']?.toDouble(),
      elapsedTime: map['elapsedTime'],
      trackedPath: (map['trackedPath'] as List?)?.map((point) => LatLng(point['lat'], point['lng'])).toList(),
      activityType: map['activityType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      title: map['title'],
      description: map['description'],
      visibility: visibility,
      photos: List<String>.from(map['photos'] ?? []),
      avgSpeed: map['avgSpeed']?.toDouble(),
      calories: map['calories']?.toDouble(),
      elevationGain: map['elevationGain']?.toDouble(),
      elevationLoss: map['elevationLoss']?.toDouble(),
      steps: map['steps']?.toInt(),
      pace: map['pace']?.toDouble(),
      competitionId: map['competitionId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'uid': uid,
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'trackedPath': trackedPath?.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
      'activityType': activityType,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'title': title,
      'description': description,
      'visibility': visibility.name,
      'photos': photos,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'elevationGain': elevationGain,
      'elevationLoss':elevationLoss,
      'steps': steps,
      'pace': pace,
      'competitionId': competitionId,
    };
  }

  // To json implemented for saving to local storage
  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'uid': uid,
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime,
      'trackedPath': trackedPath?.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
      'activityType': activityType,
      'createdAt': createdAt?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'title': title,
      'description': description,
      'visibility': visibility.name,
      'photos': photos,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
      'steps': steps,
      'pace': pace,
      'competitionId': competitionId,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    final visibilityString = json['visibility'] as String?;
    final visibility = enums.ComVisibility.values.firstWhere(
          (e) => e.name == visibilityString,
      orElse: () => enums.ComVisibility.me,
    );

    return Activity(
      activityId: json['activityId'] ?? '',
      uid: json['uid'] ?? '',
      totalDistance: json['totalDistance']?.toDouble(),
      elapsedTime: json['elapsedTime'],
      trackedPath: (json['trackedPath'] as List?)?.map((point) => LatLng(point['lat'], point['lng'])).toList(),
      activityType: json['activityType'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime']) : null,
      title: json['title'],
      description: json['description'],
      visibility: visibility,
      photos: List<String>.from(json['photos'] ?? []),
      avgSpeed: json['avgSpeed']?.toDouble(),
      calories: json['calories']?.toDouble(),
      elevationGain: json['elevationGain']?.toDouble(),
      elevationLoss: json['elevationLoss']?.toDouble(),
      steps: json['steps']?.toInt(),
      pace: json['pace']?.toDouble(),
      competitionId: json['competitionId'] ?? '',
    );
  }


  bool isEqual(Activity a) {
    return uid == a.uid &&
        activityType == a.activityType &&
        totalDistance == a.totalDistance &&
        elapsedTime == a.elapsedTime &&
        startTime == a.startTime &&
        title == a.title &&
        description == a.description &&
        visibility == a.visibility &&
        calories == a.calories &&
        avgSpeed == a.avgSpeed &&
        elevationGain == a.elevationGain &&
        elevationLoss == a.elevationLoss &&
        competitionId == a.competitionId &&
        steps == a.steps &&
        pace == a.pace &&
        AppUtils.pathEquals(trackedPath, a.trackedPath) &&
        AppUtils.listsEqual(photos, a.photos);
  }
}
