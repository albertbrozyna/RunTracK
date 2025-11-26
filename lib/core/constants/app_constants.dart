
import 'package:geolocator/geolocator.dart';

class AppConstants{
  AppConstants._();

  static List<String>genders = ["Male","Female","Other","Prefer not to say"];
  static double defaultLat = 52.2297;
  static double defaultLon = 21.0122;

  static LocationAccuracy locationAccuracy = LocationAccuracy.best;
  static int  gpsDistanceFilter = 15;
  static double gpsMaxSpeedToDetectJumps = 43;
  static double gpsMinAccuracy = 30;
}