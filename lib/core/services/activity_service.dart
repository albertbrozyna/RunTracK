import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/core/models/activity_fetch_result.dart';
import 'package:run_track/core/services/preferences_service.dart';

import '../../app/config/app_data.dart';
import '../constants/firestore_collections.dart';
import '../constants/preference_names.dart';
import '../enums/visibility.dart';
import '../models/activity.dart';



class ActivityService {
  ActivityService._();


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


  /// Fetch last {limit} activities from all users
  static Future<List<Activity>> fetchLatestActivities(int limit) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("visibility", isEqualTo: ComVisibility.everyone.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs
          .map((doc) => Activity.fromMap(doc.data()))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();

      return activities;
    } catch (e) {
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
          .map((doc) => Activity.fromMap(doc.data()))
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
      final activities = querySnapshot.docs.map((doc) => Activity.fromMap(doc.data())).toList();

      return activities;
    } catch (e) {
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last page of user activities
  static Future<ActivitiesFetchResult> fetchLatestActivitiesPage(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryActivities = FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("visibility", isEqualTo: ComVisibility.everyone.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryActivities = queryActivities.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryActivities.get();

      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs
          .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();
      return ActivitiesFetchResult(activities: activities, lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return ActivitiesFetchResult(activities: [], lastDocument: null);
    }
  }

  /// Fetch pages of friends activities
  static Future<ActivitiesFetchResult> fetchLastFriendsActivitiesPage(
    int limit,
    DocumentSnapshot? lastDocument,
    Set<String> friendsUids,
  ) async {
    if (friendsUids.isEmpty) {
      return ActivitiesFetchResult(activities: [], lastDocument: null);
    }

    try {
      Query queryActivities = FirebaseFirestore.instance
          .collection(FirestoreCollections.activities)
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: [ComVisibility.everyone.name, ComVisibility.friends.name])
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryActivities = queryActivities.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryActivities.get();

      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs
          .map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
          .where((activity) => activity.uid != FirebaseAuth.instance.currentUser?.uid) // Reject my activities
          .toList();
      return ActivitiesFetchResult(activities: activities, lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return ActivitiesFetchResult(activities: [], lastDocument: null);
    }
  }

  /// Fetch my latest activities by pages
  static Future<ActivitiesFetchResult> fetchMyLatestActivitiesPage(String uid, int limit, DocumentSnapshot? lastDocument) async {
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

      DocumentSnapshot? newLastDocument;

      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      final activities = querySnapshot.docs.map((doc) => Activity.fromMap(doc.data() as Map<String, dynamic>)).toList();

      return ActivitiesFetchResult(activities: activities, lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest activities: $e");
      return ActivitiesFetchResult(activities: [], lastDocument: null);
    }
  }

  /// Save activity to database or update if activity id is not empty
  static Future<Activity?> saveActivity(Activity activity) async {
    try {
      if (activity.activityId.isNotEmpty) {
        // Activity exists, edit it
        final docRef = FirebaseFirestore.instance
            .collection(FirestoreCollections.activities)
            .doc(activity.activityId); // Fetch existing document
        await docRef.set(activity.toMap());
        return activity;
      }

      // New activity, save it
      final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.activities).doc(); // Generate id
      activity.activityId = docRef.id;
      await docRef.set(activity.toMap());
      return activity;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Fetch last activity from local preferences
  static Future<String> fetchLastActivityFromPrefs() async {
    String? activityName = await PreferencesService.loadString(PreferenceNames.lastUsedPreference);

    final userActivities = AppData.instance.currentUser?.activityNames;
    // If saved and on the user list
    if (activityName != null) {
      return activityName;
    }
    // If not first activity or unknown
    String defaultActivity = userActivities != null && userActivities.isNotEmpty ? userActivities.first : "Unknown";

    return defaultActivity;
  }
}
