import 'package:latlong2/latlong.dart';

import '../../models/user.dart';

class AppData{
  static User? currentUser;
  static bool blockedLoginState = false;
  static bool images = false; // Handling images

  // Saved locally
  String? lastActivityString;

  // When no internet activities which we need to add
  List<String>activities = [];

  // List of current LatLng



}