import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:run_track/core/models/activity.dart';

class Storage {
  Storage._();

  static final pathStats = 'stats.json';
  static final pathActivity = 'activity.json';
  static final pathLocations = 'locations.json';

  /// Clear storage
  static Future<void> clearStorage() {
    return Future.wait([_deleteFile(pathStats), _deleteFile(pathLocations)]);
  }

  static bool statsExists() {
    return checkIfExist(pathStats);
  }

  static Future<void> _deleteFile(String filename) async {
    try {
      final path = await _getPath(filename);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("errror deleting a file");
    }
  }

  /// Get path
  static Future<String> _getPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  /// Check if file exists
  static bool checkIfExist(String path) {
    final file = File(path);
    return file.existsSync();
  }

  /// Save locations to file
  static Future<void> saveLocations(List<LatLng> locations) async {
    final path = await _getPath(Storage.pathLocations);
    final file = File(path);

    final data = locations
        .map((loc) => {'latitude': loc.latitude, 'longitude': loc.longitude})
        .toList();

    await file.writeAsString(jsonEncode(data));
  }

  /// Load locations from file
  static Future<List<LatLng>> loadLocations() async {
    try {
      final path = await _getPath(Storage.pathLocations);
      final file = File(path);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);

      return data.map((e) => LatLng(e['latitude'] as double, e['longitude'] as double)).toList();
    } catch (_) {
      return [];
    }
  }

  static bool checkIfActivityExists() {
    return checkIfExist(pathActivity);
  }

  static Future<void> deleteActivity()async{
    try{
      await Storage._deleteFile(Storage.pathActivity);
    }catch (e){
      print("$e");
    }
  }
  static Future<void> saveActivity(Activity activity) async {
    final path = await _getPath(Storage.pathStats);
    final file = File(path);
    await file.writeAsString(jsonEncode(activity.toJson()));
  }

  static Future<Activity?> loadActivity() async {
    try {
      final path = await _getPath(pathActivity);
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return Activity.fromJson(jsonDecode(content));
    } catch (_) {
      return null;
    }
  }

  /// Save stats
  static Future<void> saveStats(Map<String, dynamic> stats) async {
    final path = await _getPath(Storage.pathStats);
    final file = File(path);
    await file.writeAsString(jsonEncode(stats));
  }

  /// Load stats
  static Future<Map<String, dynamic>> loadStats() async {
    try {
      final path = await _getPath(pathStats);
      final file = File(path);
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (_) {
      return {};
    }
  }
}
