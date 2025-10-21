import 'package:latlong2/latlong.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  String fullName;
  List<String>? activityNames; // Activity names
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
  List<String> friendsUid;
  List<String> pendingInvitationsToFriends; // Sent invitations to users
  List<String> receivedInvitationsToFriends; // Received invitations to users
  List<String> receivedInvitationsToCompetitions; // Competitions uid
  List<String> participatedCompetitions; // Participated competitions

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.activityNames,
    this.email,
    this.profilePhotoUrl,
    LatLng? defaultLocation,
    DateTime? dateOfBirth,
    this.kilometers = 0,
    this.burnedCalories = 0,
    this.hoursOfActivity = 0,
    List<String>? friendsUid,
    List<String>? pendingInvitationsToFriends,
    List<String>? receivedInvitationsToFriends,
    List<String>? receivedInvitationsToCompetitions,
    List<String>? participatedCompetitions,
  }) : fullName = '${firstName.trim().toLowerCase()} ${lastName.trim().toLowerCase()}',
       pendingInvitationsToFriends = pendingInvitationsToFriends ?? [],
       receivedInvitationsToFriends = receivedInvitationsToFriends ?? [],
       receivedInvitationsToCompetitions = receivedInvitationsToCompetitions ?? [],
       participatedCompetitions = participatedCompetitions ?? [],
       friendsUid = friendsUid ?? [],
       userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);
}
