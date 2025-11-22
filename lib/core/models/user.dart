import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';


class User {
  String uid;
  String firstName;
  String lastName;
  String fullName;
  List<String> activityNames;
  String email;
  DateTime? dateOfBirth;
  DateTime? createdAt;
  String? gender;

  double kilometers;
  int burnedCalories;
  int secondsOfActivity;
  int activitiesCount;
  int competitionsCount;

  // Social functions
  Set<String> friends;
  Set<String> pendingInvitationsToFriends;
  Set<String> receivedInvitationsToFriends;
  Set<String> receivedInvitationsToCompetitions;
  Set<String> participatedCompetitions;
  String currentCompetition;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.gender,
    this.activityNames = const [],
    this.dateOfBirth,
    this.createdAt,
    this.kilometers = 0,
    this.burnedCalories = 0,
    this.secondsOfActivity = 0,
    this.activitiesCount = 0,
    this.competitionsCount = 0,
    Set<String>? friends,
    Set<String>? pendingInvitationsToFriends,
    Set<String>? receivedInvitationsToFriends,
    Set<String>? receivedInvitationsToCompetitions,
    Set<String>? participatedCompetitions,
    this.currentCompetition = "",
  })  : fullName = '${firstName.trim().toLowerCase()} ${lastName.trim().toLowerCase()}',
        pendingInvitationsToFriends = pendingInvitationsToFriends ?? {},
        receivedInvitationsToFriends = receivedInvitationsToFriends ?? {},
        receivedInvitationsToCompetitions = receivedInvitationsToCompetitions ?? {},
        participatedCompetitions = participatedCompetitions ?? {},
        friends = friends ?? {};

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'activityNames': activityNames,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'gender': gender,
      'friends': friends.toList(),
      'pendingInvitationsToFriends': pendingInvitationsToFriends.toList(),
      'receivedInvitationsToFriends': receivedInvitationsToFriends.toList(),
      'receivedInvitationsToCompetitions': receivedInvitationsToCompetitions.toList(),
      'participatedCompetitions': participatedCompetitions.toList(),
      'kilometers': kilometers,
      'burnedCalories': burnedCalories.toInt(),
      'secondsOfActivity': secondsOfActivity,
      'activitiesCount': activitiesCount,
      'competitionsCount': competitionsCount,
      'currentCompetition': currentCompetition,
    };
  }

  /// Create user from firestore collection
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      activityNames: List<String>.from(map['activityNames'] ?? []),
      friends: Set<String>.from(map['friends'] ?? []),
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
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      gender: map['gender'],
      kilometers: (map['kilometers'] ?? 0).toDouble(),
      burnedCalories: map['burnedCalories'] ?? 0,
      secondsOfActivity: map['secondsOfActivity'] ?? 0,
      activitiesCount: map['activitiesCount'] ?? 0,
      competitionsCount: map['competitionsCount'] ?? 0,
      currentCompetition: map['currentCompetition'] ?? "",
    );
  }

  User copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    List<String>? activityNames,
    String? email,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    String? gender,
    double? kilometers,
    int? burnedCalories,
    int? secondsOfActivity,
    int? activitiesCount,
    int? competitionsCount,
    Set<String>? friends,
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
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      kilometers: kilometers ?? this.kilometers,
      burnedCalories: burnedCalories ?? this.burnedCalories,
      secondsOfActivity: secondsOfActivity ?? this.secondsOfActivity,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      competitionsCount: competitionsCount ?? this.competitionsCount,
      friends: friends ?? this.friends,
      pendingInvitationsToFriends: pendingInvitationsToFriends ?? this.pendingInvitationsToFriends,
      receivedInvitationsToFriends: receivedInvitationsToFriends ?? this.receivedInvitationsToFriends,
      receivedInvitationsToCompetitions: receivedInvitationsToCompetitions ?? this.receivedInvitationsToCompetitions,
      participatedCompetitions: participatedCompetitions ?? this.participatedCompetitions,
      currentCompetition: currentCompetition ?? this.currentCompetition,
    );
  }
}