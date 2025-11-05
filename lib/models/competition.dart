import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/competition_goal.dart';
import '../common/enums/visibility.dart' as enums;
import '../common/enums/visibility.dart';

class CompetitionResult {
  final int distance;
  final int time;

  const CompetitionResult({required this.distance, required this.time});
}

class Competition {
  String competitionId; // Competition id
  String organizerUid; // Event organizer user
  String name; // Name of competition
  String? description; // Description of competition
  DateTime? startDate; // Start of the event
  DateTime? endDate; // End of the event
  DateTime? registrationDeadline; // Deadline to register for the event
  int? maxTimeToCompleteActivityHours; // Max time to complete activity
  int? maxTimeToCompleteActivityMinutes; // Max time to complete activity
  final DateTime? createdAt; // Date of creation
  Set<String> participantsUid;
  Set<String> invitedParticipantsUid;
  enums.ComVisibility visibility; // Visibility of competition
  Map<String, String>? results; // result of run first is the uid of the user and second is activity id
  String? activityType; // Allowed activity types of competition
  String? locationName; // Location name
  LatLng? location; // Location
  CompetitionGoal competitionGoalType;
  double goal; // Goal  depends what type is // distance, steps or time
  List<String> photos;  // Photos from competitions
  bool closedBeforeEndTime;

  Competition({
    this.competitionId = '',
    required this.organizerUid,
    required this.name,
    required this.visibility,
    required this.competitionGoalType,
    required this.goal,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.maxTimeToCompleteActivityHours,
    this.maxTimeToCompleteActivityMinutes,
    Set<String>? participantsUid,
    Set<String>? invitedParticipantsUid,
    this.description,
    this.activityType,
    this.results,
    this.locationName,
    this.location,
    bool? closedBeforeEndTime,
    List<String>? photos,
  }) : closedBeforeEndTime = closedBeforeEndTime ?? false,
        photos = photos ?? [],
  participantsUid = participantsUid ?? {},
  invitedParticipantsUid = invitedParticipantsUid ?? {};


  // TODO HANDLE RESULTS AND PHOTOS
  factory Competition.fromMap(Map<String, dynamic> map) {
    return Competition(
      competitionId: map['competitionId'],
      organizerUid: map['organizerUid'] ?? '',
      name: map['name'] ?? '',
      competitionGoalType: parseCompetitionGoal(map['competitionGoal']) ?? CompetitionGoal.distance,
      goal: (map['goal'] is num) ? (map['goal'] as num).toDouble() : 0.0,
      // To num and then to double to avoid null
      visibility: parseVisibility(map['visibility']) ?? enums.ComVisibility.me,
      description: map['description'],
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      registrationDeadline: map['registrationDeadline'] != null ? (map['registrationDeadline'] as Timestamp).toDate() : null,
      maxTimeToCompleteActivityHours: map['maxTimeToCompleteActivityHours'],
      maxTimeToCompleteActivityMinutes: map['maxTimeToCompleteActivityMinutes'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      participantsUid: map['participantsUid'] != null ? Set<String>.from(map['participantsUid']) : {},
      invitedParticipantsUid: map['invitedParticipantsUid'] != null ? Set<String>.from(map['invitedParticipantsUid']) : {},
      activityType: map['activityType'],
      // TODO
      //results: map['results'] != null
      // ? Map<String, double>.from(map['results'].map((key, value) => MapEntry(key, (value as num).toDouble())))
      //: {},
      locationName: map['locationName'],
      location: (map['latitude'] != null && map['longitude'] != null)
          ? LatLng((map['latitude'] as num).toDouble(), (map['longitude'] as num).toDouble())
          : null,
    );
  }

  /// Covert competition to firestore
  Map<String, dynamic> toMap(Competition competition) {
    return {
      'competitionId': competition.competitionId,
      'organizerUid': competition.organizerUid,
      'name': competition.name,
      'competitionGoal': competition.competitionGoalType.toString(),
      'description': competition.description,
      'visibility': competition.visibility.toString(),
      'startDate': competition.startDate != null ? Timestamp.fromDate(competition.startDate!) : null,
      'endDate': competition.endDate != null ? Timestamp.fromDate(competition.endDate!) : null,
      'registrationDeadline': competition.registrationDeadline != null ? Timestamp.fromDate(competition.registrationDeadline!) : null,
      'maxTimeToCompleteActivityHours': competition.maxTimeToCompleteActivityHours,
      'maxTimeToCompleteActivityMinutes': competition.maxTimeToCompleteActivityMinutes,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'participantsUids': competition.participantsUid,
      'invitedParticipantsUids': competition.invitedParticipantsUid,
      'activityType': competition.activityType,
      'results': competition.results ?? {},
      'locationName': competition.locationName,
      'latitude': competition.location?.latitude,
      'longitude': competition.location?.longitude,
    };
  }

  // TODO ADD ALL FIELDS FROM COMPETITION
  /// Compare two competitions and check if they are equal
  static bool competitionsEqual(Competition c1, Competition c2) {
    return c1.competitionId == c2.competitionId &&
        c1.organizerUid == c2.organizerUid &&
        c1.name == c2.name &&
        c1.description == c2.description &&
        c1.visibility == c2.visibility &&
        c1.startDate == c2.startDate &&
        c1.endDate == c2.endDate &&
        c1.registrationDeadline == c2.registrationDeadline &&
        c1.maxTimeToCompleteActivityHours == c2.maxTimeToCompleteActivityHours &&
        c1.maxTimeToCompleteActivityMinutes == c2.maxTimeToCompleteActivityMinutes &&
        c1.activityType == c2.activityType &&
        AppUtils.setsEqual(c1.participantsUid, c2.participantsUid) &&
        AppUtils.setsEqual(c1.invitedParticipantsUid, c2.invitedParticipantsUid) &&
        // TODO
        //AppUtils.mapsEqual(c1.results, c2.results) &&
        c1.locationName == c2.locationName &&
        c1.location?.latitude == c2.location?.latitude &&
        c1.location?.longitude == c2.location?.longitude;
  }

}
