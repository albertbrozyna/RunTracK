import 'package:cloud_firestore/cloud_firestore.dart';
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
  String currentCompetition;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.gender,
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
    this.currentCompetition = "",
  })  : fullName = '${firstName.trim().toLowerCase()} ${lastName.trim().toLowerCase()}',
        pendingInvitationsToFriends = pendingInvitationsToFriends ?? {},
        receivedInvitationsToFriends = receivedInvitationsToFriends ?? {},
        receivedInvitationsToCompetitions =
            receivedInvitationsToCompetitions ?? {},
        participatedCompetitions = participatedCompetitions ?? {},
        friendsUid = friendsUid ?? {},
        userDefaultLocation = defaultLocation ?? LatLng(0.0, 0.0);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'activityNames': activityNames ?? [],
      'dateOfBirth':
      dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'gender': gender,
      'friendsUid': friendsUid.toList(),
      'pendingInvitationsToFriends':
      pendingInvitationsToFriends.toList(),
      'receivedInvitationsToFriends':
      receivedInvitationsToFriends.toList(),
      'receivedInvitationsToCompetitions':
      receivedInvitationsToCompetitions.toList(),
      'participatedCompetitions':
      participatedCompetitions.toList(),
      'profilePhotoUrl': profilePhotoUrl,
      'userDefaultLocation': {
        'latitude': userDefaultLocation.latitude,
        'longitude': userDefaultLocation.longitude,
      },
      'kilometers': kilometers,
      'burnedCalories': burnedCalories,
      'hoursOfActivity': hoursOfActivity,
      'activitiesCount': activitiesCount,
      'competitionsCount': competitionsCount,
      'currentCompetition': currentCompetition,
    };
  }

  /// Create user from firestore collection
  factory User.fromMap(Map<String, dynamic> map) {
    final location = map['userDefaultLocation'];
    return User(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      activityNames: List<String>.from(map['activityNames'] ?? []),
      friendsUid: Set<String>.from(map['friendsUid'] ?? []),
      pendingInvitationsToFriends: Set<String>.from(
        map['pendingInvitationsToFriends'] ?? [],
      ),
      receivedInvitationsToFriends: Set<String>.from(
        map['receivedInvitationsToFriends'] ?? [],
      ),
      receivedInvitationsToCompetitions: Set<String>.from(
        map['receivedInvitationsToCompetitions'] ?? [],
      ),
      participatedCompetitions: Set<String>.from(
        map['participatedCompetitions'] ?? [],
      ),
      profilePhotoUrl: map['profilePhotoUrl'],
      defaultLocation: location != null
          ? LatLng(
        (location['latitude'] ?? 0.0).toDouble(),
        (location['longitude'] ?? 0.0).toDouble(),
      )
          : LatLng(0.0, 0.0),
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      gender: map['gender'],
      kilometers: map['kilometers'] ?? 0,
      burnedCalories: map['burnedCalories'] ?? 0,
      hoursOfActivity: map['hoursOfActivity'] ?? 0,
      activitiesCount: map['activitiesCount'] ?? 0,
      competitionsCount: map['competitionsCount'] ?? 0,
      currentCompetition: map['currentCompetition'] ?? "",
    );
  }

  User copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? fullName,
    List<String>? activityNames,
    String? email,
    String? profilePhotoUrl,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    String? gender,
    LatLng? userDefaultLocation,
    int? kilometers,
    int? burnedCalories,
    int? hoursOfActivity,
    int? activitiesCount,
    int? competitionsCount,
    Set<String>? friendsUid,
    Set<String>? pendingInvitationsToFriends,
    Set<String>? receivedInvitationsToFriends,
    Set<String>? receivedInvitationsToCompetitions,
    Set<String>? participatedCompetitions,
    String? currentCompetition,
  }) {
    return User(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      activityNames: activityNames ?? this.activityNames,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      defaultLocation: userDefaultLocation ?? this.userDefaultLocation,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      kilometers: kilometers ?? this.kilometers,
      burnedCalories: burnedCalories ?? this.burnedCalories,
      hoursOfActivity: hoursOfActivity ?? this.hoursOfActivity,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      competitionsCount: competitionsCount ?? this.competitionsCount,
      friendsUid: friendsUid ?? this.friendsUid,
      pendingInvitationsToFriends:
      pendingInvitationsToFriends ?? this.pendingInvitationsToFriends,
      receivedInvitationsToFriends:
      receivedInvitationsToFriends ?? this.receivedInvitationsToFriends,
      receivedInvitationsToCompetitions: receivedInvitationsToCompetitions ??
          this.receivedInvitationsToCompetitions,
      participatedCompetitions:
      participatedCompetitions ?? this.participatedCompetitions,
      currentCompetition: currentCompetition ?? this.currentCompetition,
    );
  }
}