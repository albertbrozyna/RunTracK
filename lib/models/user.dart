import 'package:latlong2/latlong.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  List<String>? activityNames;
  String? email;
  String? profilePhotoUrl; // Profile photo url
  DateTime? dateOfBirth;
  String? gender;

  // Default location for user
  LatLng userDefaultLocation;

  // User stats
  int kilometers;
  int burnedCalories;
  int hoursOfActivity;

  // Social functions
  List<String>? friendsUids;
  List<String> pendingInvitations ; // Sent invitations to users
  List<String> receivedInvitations; // Received invitations to users

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.friendsUids,
    this.activityNames,
    this.email,
    this.profilePhotoUrl,
    LatLng? defaultLocation,
    DateTime? dateOfBirth,
    this.kilometers = 0,
    this.burnedCalories = 0,
    this.hoursOfActivity = 0,
    List<String>? pendingInvitations,
    List<String>? receivedInvitations,
  }) : pendingInvitations = pendingInvitations ?? [],
       receivedInvitations = receivedInvitations ?? [],
       userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);
}
