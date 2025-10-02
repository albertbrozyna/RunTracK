import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
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
