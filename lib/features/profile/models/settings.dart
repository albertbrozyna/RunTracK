
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AppSettings{
  static LocationAccuracy locationAccuracy = LocationAccuracy.best;
  static int updateLocationDistance = 5;
  static LatLng defaultLocation  = LatLng(52.2297, 21.0122); // Default location when there is no gps
  static int saveIntervalTime = 10; // Time interval between saves to a local storage a training state





}