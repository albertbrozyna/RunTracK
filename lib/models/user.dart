import 'package:latlong2/latlong.dart';

import 'activity.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  List<Activity>?activities;
  List<String>?activityNames;
  List<String>?friendsUids;
  String? email;
  // Default location for user
  LatLng userDefaultLocation;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    this.activities,
    this.friendsUids,
    this.activityNames,
    this.email,
    LatLng? defaultLocation,
}) :  userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);

}