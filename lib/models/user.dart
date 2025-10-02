import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'activity.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  List<String>?activityNames;
  List<String>?friendsUids;
  String? email;
  String? profilePhotoUrl;   // Profile photo url
  DateTime? dateOfBirth;
  // Default location for user
  LatLng userDefaultLocation;
  // User stats
  int kilometers;
  int burnedCalories;
  int hoursOfActivity;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    this.friendsUids,
    this.activityNames,
    this.email,
    this.profilePhotoUrl,
    LatLng? defaultLocation,
    DateTime? dateOfBirth,
    this.kilometers = 0,
    this.burnedCalories = 0,
    this.hoursOfActivity = 0,
}) :  userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'activityNames': activityNames ?? [],
      'friendsUids': friendsUids ?? [],
      'profilePhotoUrl': profilePhotoUrl,
      'userDefaultLocation': {
        'latitude': userDefaultLocation.latitude,
        'longitude': userDefaultLocation.longitude,
      },
    };
  }

  /// Saves the user object to Firestore
  Future<bool> saveUser() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(toMap());
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }
}