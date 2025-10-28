import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/competition_goal.dart';
import '../common/enums/visibility.dart' as enums;

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
}
