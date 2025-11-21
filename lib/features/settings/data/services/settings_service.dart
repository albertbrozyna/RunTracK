import 'package:geolocator/geolocator.dart';
import 'package:run_track/app/config/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static String accuracyEnumToString(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.best:
        return 'best';
      case LocationAccuracy.high:
        return 'high';
      case LocationAccuracy.medium:
        return 'medium';
      case LocationAccuracy.low:
        return 'low';
      default:
        return 'best';
    }
  }

  static LocationAccuracy getAccuracyEnum(String name) {
    switch (name) {
      case 'best':
        return LocationAccuracy.best;
      case 'high':
        return LocationAccuracy.high;
      case 'medium':
        return LocationAccuracy.medium;
      case 'low':
        return LocationAccuracy.low;
      default:
        return LocationAccuracy.best;
    }
  }

  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gps_distance_filter', AppSettings.instance.gpsDistanceFilter ?? 15);
    await prefs.setDouble('gps_min_accuracy', AppSettings.instance.gpsMinAccuracy ?? 30);
    await prefs.setDouble('gps_max_speed', AppSettings.instance.gpsMaxSpeedToDetectJumps ?? 43);
    await prefs.setString(
      'gps_accuracy_level',
      SettingsService.accuracyEnumToString(
        AppSettings.instance.gpsAccuracyLevel ?? LocationAccuracy.best,
      ),
    );
  }

  static void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    AppSettings.instance.gpsDistanceFilter = prefs.getInt('gps_distance_filter') ?? 15;
    AppSettings.instance.gpsMinAccuracy = prefs.getDouble('gps_min_accuracy') ?? 30.0;
    AppSettings.instance.gpsMaxSpeedToDetectJumps =
        prefs.getDouble('gps_max_speed_to_detect_jumps') ?? 43.0;
    String accuracy = prefs.getString('gps_accuracy_level') ?? 'best';
    AppSettings.instance.gpsAccuracyLevel = getAccuracyEnum(accuracy);
  }
}
