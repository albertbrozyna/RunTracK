import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/colors.dart';

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

enum MessageType{
  info,
  success,
  warning,
  error
}

class AppUtils {
  static String formatDateTime(DateTime? time, {bool onlyDate = false}) {
    if (time == null) {
      return "";
    }

    if(onlyDate){
      return "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ";
    }

    return "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} "
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // Show message using scaffold
  static void showMessage(BuildContext context, String message, {MessageType messageType = MessageType.info}) {
    String title = "";
    Color bgColor;
    if(MessageType.info == messageType){
      bgColor = AppColors.scaffoldMessengerInfoColor;
    }else if(MessageType.success == messageType){
      bgColor = AppColors.scaffoldMessengerSuccessColor;
    }else if(MessageType.warning == messageType){
      bgColor = AppColors.scaffoldMessengerWarningColor;
    }else{
      bgColor = AppColors.scaffoldMessengerErrorColor;
    }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,textAlign: TextAlign.center,style: TextStyle(
          fontSize: AppUiConstants.textSizeApp
        ),),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
      ),
    );
  }

  /// Fit map to path
  static void fitMapToPath(List<LatLng> path, MapController controller) {
    if (path.isEmpty || path.length == 1) {
      return;
    }
    final bounds = LatLngBounds.fromPoints(path);
    controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(AppUiConstants.flutterMapInnerPaddingRectangleBounds)),
    );
  }

  /// Compare paths
  static bool pathEquals(List<LatLng>? p1, List<LatLng>? p2) {
    if (p1 == null && p2 == null) {
      return true;
    }
    if (p1 == null || p2 == null) {
      return false;
    }
    if (p1.length != p2.length) {
      return false;
    }
    for (int i = 0; i < p1.length; i++) {
      if (p1[i].latitude != p2[i].latitude || p1[i].longitude != p2[i].longitude) {
        return false;
      }
    }
    return true;
  }

  /// Comp any lists
  static bool listsEqual(List<String>? l1, List<String>? l2) {
    if (l1 == null && l2 == null) {
      return true;
    }
    if (l1 == null || l2 == null) {
      return false;
    }
    if (l1.length != l2.length) {
      return false;
    }
    for (int i = 0; i < l1.length; ++i) {
      if (l1[i] != l2[i]) {
        return false;
      }
    }
    return true;
  }

  /// Comp sets
  static bool setsEqual(Set<String>? s1, Set<String>? s2) {
    if (s1 == null && s2 == null) return true;
    if (s1 == null || s2 == null) return false;
    if (s1.length != s2.length) return false;
    return s1.containsAll(s2);
  }

  static bool mapsEqual<A, B>(Map<A, B>? map1, Map<A, B>? map2) {
    if (map1 == null && map2 == null) {
      return true;
    }
    if (map1 == null || map2 == null) {
      return false;
    }
    if (map1.length != map2.length) {
      return false;
    }

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) {
        return false;
      }

      if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  static Future<DateTime?> pickDate(
    BuildContext context,
    DateTime firstDate,
    DateTime lastDate,
    TextEditingController? dateController,
      bool onlyDate
  ) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: firstDate, lastDate: lastDate);

    if (picked == null) {
      return null;
    }

    if(onlyDate){
      dateController?.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} ";
      return picked;
    }

    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (pickedTime == null) {
      return null;
    }
    DateTime fullDateTime = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);

    String formattedDateTime =
        "${fullDateTime.year}-${fullDateTime.month.toString().padLeft(2, '0')}-${fullDateTime.day.toString().padLeft(2, '0')} "
        "${fullDateTime.hour.toString().padLeft(2, '0')}:${fullDateTime.minute.toString().padLeft(2, '0')}";

    if (dateController != null) {
      dateController.text = formattedDateTime;
    }
    return fullDateTime;
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
