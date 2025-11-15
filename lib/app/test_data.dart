import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/enums/visibility.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';

Future<void> generate30Competitions() async {
  for (int i = 1; i <= 30; i++) {
    final competition = Competition(
      organizerUid: FirebaseAuth.instance.currentUser?.uid ?? "",
      name: "Test Competition $i",
      description: "Auto-generated competition number $i",
      createdAt: DateTime.now(),
      startDate: DateTime.now().add(Duration(days: 1)),
      endDate: DateTime.now().add(Duration(days: 7)),
      registrationDeadline: DateTime.now().add(Duration(hours: 12)),
      maxTimeToCompleteActivityHours: 2,
      maxTimeToCompleteActivityMinutes: 30,
      visibility: ComVisibility.everyone,
      distanceToGo: 10.0 + i,
      participantsUid: {},
      invitedParticipantsUid: {},
      locationName: "Location $i",
      location: LatLng(52.0 + i * 0.01, 21.0 + i * 0.01),
      activityType: "running",
      photos: [],
      results: {},
    );

    final savedCompetition = await CompetitionService.saveCompetition(competition);

    if (savedCompetition != null) {
      print("Saved competition: ${savedCompetition.competitionId}");
    } else {
      print("Failed to save competition $i");
    }
  }

  print("=== 30 competitions created and saved ===");
}
