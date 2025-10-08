import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {

  // Show message using scaffold
  static void showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
