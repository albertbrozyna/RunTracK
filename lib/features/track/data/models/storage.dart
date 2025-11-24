import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:run_track/core/models/activity.dart';

class ActivityStorage {
  ActivityStorage._();

  static const String _filename = 'activity.json';

  static Future<String> _getFullPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_filename';
  }

  static Future<bool> checkIfActivityExists() async {
    final path = await _getFullPath();
    return File(path).exists();
  }

  static Future<void> deleteActivity() async {
    try {
      final path = await _getFullPath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting activity: $e");
    }
  }


  /// Save activity
  static Future<void> saveActivity(Activity activity) async {
    try {
      final path = await _getFullPath();
      final file = File(path);
      await file.writeAsString(jsonEncode(activity.toJson()));
    } catch (e) {
      print("Error saving activity: $e");
    }
  }
  static Future<Activity?> loadActivity() async {
    try {
      final path = await _getFullPath();
      final file = File(path);

      if (!await file.exists()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      return Activity.fromJson(jsonDecode(content));
    } catch (e) {
      print("Error loading activity: $e");
      return null;
    }
  }
}
