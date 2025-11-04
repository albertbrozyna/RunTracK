import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class Storage {
  final pathStats = 'stats';
  final pathLocations = 'locations';

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
    final path = await _getPath('locations.json');
    final file = File(path);

    final data = locations.map((loc) => {
      'latitude': loc.latitude,
      'longitude': loc.longitude,
    }).toList();

    await file.writeAsString(jsonEncode(data));
  }

  /// Load locations from file
  static Future<List<LatLng>> loadLocations() async {
    try {
      final path = await _getPath('locations.json');
      final file = File(path);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);

      return data.map((e) => LatLng(
        e['latitude'] as double,
        e['longitude'] as double,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save stats
  static Future<void> saveStats(Map<String, dynamic> stats) async {
    final path = await _getPath('stats.json');
    final file = File(path);
    await file.writeAsString(jsonEncode(stats));
  }

  /// Load stats
  static Future<Map<String, dynamic>> loadStats() async {
    try {
      final path = await _getPath('stats.json');
      final file = File(path);
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (_) {
      return {};
    }
  }
}
