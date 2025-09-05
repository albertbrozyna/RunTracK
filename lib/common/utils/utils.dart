import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';
import 'package:run_track/models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart' as model;
import 'package:run_track/common/enums/visibility.dart';

class AppUtils {
  /// Method to fetch user by his uid
  static Future<model.User?> fetchUser(
    String uid,
    BuildContext context,
    bool currentUserData,
    bool allActivities,
  ) async {
    // To get a other users names and activities user needs to be logged
    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      // User is not logged in
      AppData.currentUser = null;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => StartPage()),
        (Route<dynamic> route) => false,
      );
      return null;
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;

      // We are fetching current user so we get a full data
      if (FirebaseAuth.instance.currentUser?.uid != null &&
          FirebaseAuth.instance.currentUser?.uid == uid) {
        AppData.currentUser = new model.User(
          uid: FirebaseAuth.instance.currentUser!.uid,
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          activities: [],
          activityNames: userData['activities'],
          friendsUids: userData['friends'],
          email: userData['email'],
        );

        // Fetch all activities
        final userActivities = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("activities")
            .orderBy('createdAt')
            .get();

        if (allActivities) {
          List<Activity> activities = userActivities.docs.map((doc) {
            final actData = doc.data();

            return Activity(
              actData['totalDistance']?.toDouble(),
              Duration(seconds: actData['elapsedTime'] ?? 0),
              (actData['trackedPath'] as List<dynamic>?)
                  ?.map((e) => LatLng(e['lat'], e['lng']))
                  .toList(),
              actData['activityType'],
              (actData['startTime'] as Timestamp?)?.toDate(),
              actData['title'],
              actData['description'],
              actData['visibility'],
              actData['photos']
            );
          }).toList();
          AppData.currentUser?.activities = activities.cast<Activity>();
        }

        return AppData.currentUser;
      }

      // Fetching not current user but different
      if (FirebaseAuth.instance.currentUser?.uid != null &&
          FirebaseAuth.instance.currentUser?.uid != uid) {
        model.User user = new model.User(
          uid: uid,
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          activities: [],
          friendsUids: userData['friends'],
          email: userData['email'],
        );

        // Fetch all activities
        if (allActivities) {
          final userActivities = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("activities")
              .orderBy('createdAt')
              .get();

          List<Activity> activities = userActivities.docs.map((doc) {
            final actData = doc.data();
            return Activity(
              actData['totalDistance']?.toDouble(),
              Duration(seconds: actData['elapsedTime'] ?? 0),
              (actData['trackedPath'] as List<dynamic>?)
                  ?.map((e) => LatLng(e['lat'], e['lng']))
                  .toList(),
              actData['activityType'],
              (actData['startTime'] as Timestamp?)?.toDate(),
              actData['title'],
              actData['description'],
              actData['visibility'],
              actData['photos'],
            );
          }).toList();
          user.activities = activities.cast<Activity>();
        }

        return user;
      }
    }
    return null;
  }

  void fetchLastActivities() async {}

  static Future<List<Activity>?> fetchUserActivities(String uid, int limit) async {
    // Check if user exists
    DocumentSnapshot user = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (!user.exists) {
      return null;
    }
    // Fetch user activities
    final userActivities = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("activities")
        .orderBy('createdAt')
        .limit(limit)
        .get();

    // Cast to activity class
    return userActivities.docs.map((doc) {
      final actData = doc.data();
      return Activity(
        actData['totalDistance']?.toDouble(),
        Duration(seconds: actData['elapsedTime'] ?? 0),
        (actData['trackedPath'] as List<dynamic>?)
            ?.map((e) => LatLng(e['lat'], e['lng']))
            .toList(),
        actData['activityType'],
        (actData['startTime'] as Timestamp?)?.toDate(),
        actData['title'],
        actData['description'],
        actData['visibility'],
        actData['photos']
      );
    }).toList();
  }

  /// Method that formats date to show it in user friendly way
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  /// Method to save a string to shared preferences
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Method to load a string from shared preferences
  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Method to remove a key from shared preferences
  static Future<void> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Method do save list of strings
  Future<void> saveListString(key, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }

  /// Returns a predefined list of fitness activities
  static List<String> getDefaultActivities() {
    return [
      "Running",
      "Jogging",
      "Walking",
      "Cycling",
      "Mountain Biking",
      "Hiking",
      "Swimming",
      "Rowing",
      "Kayaking",
      "Canoeing",
      "Surfing",
      "Stand-up Paddleboarding",
      "Jump Rope",
      "Elliptical Training",
      "Stair Climbing",
      "CrossFit",
      "HIIT",
      "Strength Training",
      "Weightlifting",
      "Bodyweight Training",
      "Pilates",
      "Yoga",
      "Dance",
      "Zumba",
      "Boxing",
      "Kickboxing",
      "Basketball",
      "Football (Soccer)",
      "Volleyball",
      "Tennis",
      "Table Tennis",
      "Badminton",
      "Baseball",
      "Softball",
      "Rugby",
      "Cricket",
      "Golf",
      "Rock Climbing",
      "Skiing",
      "Snowboarding",
      "Ice Skating",
      "Skateboarding",
    ];
  }
}
