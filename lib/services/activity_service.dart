import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/visibility.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/theme/preference_names.dart';

import '../common/utils/app_data.dart';

class ActivityService {
  /// Format elapsed time from duration to hh:mm:ss
  static String formatElapsedTime(Duration duration) {
    return formatElapsedTimeFromSeconds(duration.inSeconds);
  }

  /// Format elapsed time from seconds to hh:mm:ss
  static String formatElapsedTimeFromSeconds(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return "$hours:$minutes:$secs";
  }

  /// Convert Firestore data to Activity object
  static Activity fromMap(Map<String, dynamic> map) {
    return Activity(
      uid: map['uid'],
      totalDistance: map['totalDistance']?.toDouble(),
      elapsedTime: map['elapsedTime'],
      trackedPath: (map['trackedPath'] as List?)
          ?.map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      activityType: map['activityType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      title: map['title'],
      description: map['description'],
      visibility: parseVisibility( map['visibility']) ?? Visibility.me,
      photos: List<String>.from(map['photos'] ?? []),
      avgSpeed: map['avgSpeed']?.toDouble(),
      calories: map['calories']?.toDouble(),
      elevationGain: map['elevationGain']?.toDouble(),
      steps: map['steps']?.toInt(),
      pace: map['pace']?.toDouble(),
    );
  }

  /// Convert Activity object to Firestore map
  static Map<String, dynamic> toMap(Activity activity) {
    return {
      'totalDistance': activity.totalDistance,
      'elapsedTime': activity.elapsedTime,
      'trackedPath': activity.trackedPath
          ?.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude})
          .toList(),
      'activityType': activity.activityType,
      'createdAt': activity.createdAt ?? FieldValue.serverTimestamp(),
      'startTime': activity.startTime != null
          ? Timestamp.fromDate(activity.startTime!)
          : null,
      'title': activity.title,
      'description': activity.description,
      'visibility': activity.visibility.toString(),
      'photos': activity.photos,
      'calories': activity.calories,
      'avgSpeed': activity.avgSpeed,
      'elevationGain': activity.elevationGain,
      'steps': activity.steps,
      'pace': activity.pace,
    };
  }

  /// Fetch last {limit} activities from all users
  static Future<List<Activity>> fetchLatestActivities(int limit) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where("visibility", isEqualTo: "EVERYONE")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data()))
          .toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last friend activities
  static Future<List<Activity>> fetchLastFriendsActivities(
    List<String> friendsUids,
    int limit,
  ) async {
    List<Activity> lastActivities = [];
    if (friendsUids.isEmpty) {
      return lastActivities;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: ["everyone", "friends"])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data()))
          .toList();

      lastActivities.addAll(activities);

      // Sort activities by date and take limit
      lastActivities.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return lastActivities.take(limit).toList();
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching friends' activities: $e");
      return [];
    }
  }

  static Future<List<Activity>> fetchLatestUserActivities(
    String uid,
    int limit,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where("uid", isEqualTo: "me")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data()))
          .toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  static Future<bool> saveActivity(Activity activity) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('activities')
          .doc(); // Generate id
      activity.activityId = docRef.id;
      await docRef.set(ActivityService.toMap(activity));
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Fetch last activity from local preferences
  static Future<String> fetchLastActivityFromPrefs() async {
    String? activityName = await PreferencesService.loadString(
      PreferenceNames.lastUsedPreference,
    );

    final userActivities = AppData.currentUser?.activityNames;
    // If saved and on the user list
    if (activityName != null) {
      return activityName;
    }
    // If not first activity or unknown
    String defaultActivity = userActivities != null && userActivities.isNotEmpty
        ? userActivities.first
        : "Unknown";

    return defaultActivity;
  }
}
