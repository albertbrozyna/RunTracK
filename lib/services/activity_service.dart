import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/visibility.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/theme/preference_names.dart';

import '../common/utils/app_data.dart';
import '../constants/firestore_names.dart';

class ActivityService {
  static DocumentSnapshot? lastFetchedDocumentMyActivities;
  static DocumentSnapshot? lastFetchedDocumentFriendsActivities;
  static DocumentSnapshot? lastFetchedDocumentAllActivities;

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
      activityId: map['activityId'],
      uid: map['uid'],
      totalDistance: map['totalDistance']?.toDouble(),
      elapsedTime: map['elapsedTime'],
      trackedPath: (map['trackedPath'] as List?)?.map((point) => LatLng(point['lat'], point['lng'])).toList(),
      activityType: map['activityType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      title: map['title'],
      description: map['description'],
      visibility: parseVisibility(map['visibility']) ?? ComVisibility.me,
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
      'activityId': activity.activityId,
      'uid': activity.uid,
      'totalDistance': activity.totalDistance,
      'elapsedTime': activity.elapsedTime,
      'trackedPath': activity.trackedPath?.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
      'activityType': activity.activityType,
      'createdAt': activity.createdAt ?? FieldValue.serverTimestamp(),
      'startTime': activity.startTime != null ? Timestamp.fromDate(activity.startTime!) : null,
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
          .where("visibility", isEqualTo: "Visibility.everyone")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data()))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last friend activities
  static Future<List<Activity>> fetchLastFriendsActivities(List<String> friendsUids, int limit) async {
    List<Activity> lastActivities = [];
    if (friendsUids.isEmpty) {
      return lastActivities;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: ["Visibility.everyone", "Visibility.friends"])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data()))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid)
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

  static Future<List<Activity>> fetchLatestUserActivities(String uid, int limit) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("uid", isEqualTo: uid.trim())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs.map((doc) => ActivityService.fromMap(doc.data())).toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last page of user activities
  static Future<List<Activity>> fetchLatestActivitiesPage(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryActivities = FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("visibility", isEqualTo: "Visibility.everyone")
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryActivities = queryActivities.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryActivities.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentAllActivities = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data() as Map<String, dynamic>))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();
      return activities;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  /// Fetch pages of friends activities
  static Future<List<Activity>> fetchLastFriendsActivitiesPage(int limit, DocumentSnapshot? lastDocument, Set<String> friendsUids) async {
    if (friendsUids.isEmpty) {
      return [];
    }

    try {
      Query queryActivities = FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: ["Visibility.everyone", "Visibility.friends"])
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryActivities = queryActivities.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryActivities.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentFriendsActivities = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs
          .map((doc) => ActivityService.fromMap(doc.data() as Map<String, dynamic>))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();
      return activities;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  /// Fetch my latest activities by pages
  static Future<List<Activity>> fetchMyLatestActivitiesPage(String uid, int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryActivities = FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("uid", isEqualTo: uid.trim())
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryActivities = queryActivities.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryActivities.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentMyActivities = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs.map((doc) => ActivityService.fromMap(doc.data() as Map<String, dynamic>)).toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Save activity to database or update if activity id is not empty
  static Future<bool> saveActivity(Activity activity) async {
    try {
      if (activity.activityId.isNotEmpty) {
        // Activity exists, edit it
        final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.activities).doc(activity.activityId); // Fetch existing document
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.set(ActivityService.toMap(activity));
          return true;
        }
      }
      // New activity, save it
      final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.activities).doc(); // Generate id
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
    String? activityName = await PreferencesService.loadString(PreferenceNames.lastUsedPreference);

    final userActivities = AppData.currentUser?.activityNames;
    // If saved and on the user list
    if (activityName != null) {
      return activityName;
    }
    // If not first activity or unknown
    String defaultActivity = userActivities != null && userActivities.isNotEmpty ? userActivities.first : "Unknown";

    return defaultActivity;
  }

  /// Compare two activities and check if they are equal
  static bool activitiesEqual(Activity a1, Activity a2) {
    return a1.uid == a2.uid &&
        a1.activityType == a2.activityType &&
        a1.totalDistance == a2.totalDistance &&
        a1.elapsedTime == a2.elapsedTime &&
        a1.startTime == a2.startTime &&
        a1.title == a2.title &&
        a1.description == a2.description &&
        a1.visibility == a2.visibility &&
        a1.calories == a2.calories &&
        a1.avgSpeed == a2.avgSpeed &&
        a1.elevationGain == a2.elevationGain &&
        a1.steps == a2.steps &&
        a1.pace == a2.pace &&
        AppUtils.pathEquals(a1.trackedPath, a2.trackedPath) &&
        AppUtils.listsEqual(a1.photos, a2.photos);
  }


}
