
import 'package:geolocator/geolocator.dart';

class AppConstants{
  AppConstants._();

  static const List<String>genders = ["Male","Female","Other","Prefer not to say"];
  static const double defaultLat = 52.2297;
  static const double defaultLon = 21.0122;

  static const LocationAccuracy locationAccuracy = LocationAccuracy.best;
  static const int  gpsDistanceFilter = 15;
  static const double gpsMaxSpeedToDetectJumps = 43;
  static const double gpsMinAccuracy = 30;

  static const double weightKg = 70;
  static const int height = 170;
}