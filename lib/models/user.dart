import 'package:latlong2/latlong.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  String fullName;
  List<String>? activityNames; // Activity names
  String email;
  String? profilePhotoUrl; // Profile photo url
  DateTime? dateOfBirth;
  DateTime? createdAt;
  String? gender;
  // Default location for user
  LatLng userDefaultLocation;

  // User stats
  int kilometers;
  int burnedCalories;
  int hoursOfActivity;
  int activitiesCount;
  int competitionsCount;

  // Social functions
  Set<String> friendsUid;
  Set<String> pendingInvitationsToFriends; // Sent invitations to users
  Set<String> receivedInvitationsToFriends; // Received invitations to users
  Set<String> receivedInvitationsToCompetitions; // Competitions uid
  Set<String> participatedCompetitions; // Participated competitions

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    this.activityNames,
    this.profilePhotoUrl,
    LatLng? defaultLocation,
    this.dateOfBirth,
    this.createdAt,
    this.kilometers = 0,
    this.burnedCalories = 0,
    this.hoursOfActivity = 0,
    this.activitiesCount = 0,
    this.competitionsCount = 0,
    Set<String>? friendsUid,
    Set<String>? pendingInvitationsToFriends,
    Set<String>? receivedInvitationsToFriends,
    Set<String>? receivedInvitationsToCompetitions,
    Set<String>? participatedCompetitions,
  }) : fullName = '${firstName.trim().toLowerCase()} ${lastName.trim().toLowerCase()}',
       pendingInvitationsToFriends = pendingInvitationsToFriends ?? {},
       receivedInvitationsToFriends = receivedInvitationsToFriends ?? {},
       receivedInvitationsToCompetitions = receivedInvitationsToCompetitions ?? {},
       participatedCompetitions = participatedCompetitions ?? {},
       friendsUid = friendsUid ?? {},
       userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);
}
