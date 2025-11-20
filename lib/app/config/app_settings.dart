
import 'package:geolocator/geolocator.dart';

class AppSettings{
  AppSettings._privateConstructor();
  static final AppSettings _instance = AppSettings._privateConstructor();
  static AppSettings get instance => _instance;


  int? gpsDistanceFilter; // Distance change needed to fetch location
  double? gpsMaxSpeedToDetectJumps;
  LocationAccuracy? gpsAccuracyLevel;
  double? gpsMinAccuracy; // Min accuracy to add a position

}