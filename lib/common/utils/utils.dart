import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/theme/ui_constants.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Fit map to path
  static void fitMapToPath(List<LatLng> path, MapController controller) {
    if (path.isEmpty || path.length == 1) {
      return;
    }
    final bounds = LatLngBounds.fromPoints(path);
    controller.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(AppUiConstants.innerPaddingRectangleBounds)));
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
