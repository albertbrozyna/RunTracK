import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? profilePhotoUrl;   // Profile photo url
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

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'activityNames': activityNames ?? [],
      'friendsUids': friendsUids ?? [],
      'activities': activities?.map((a) => a.toMap()).toList() ?? [],
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