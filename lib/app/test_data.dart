import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/enums/visibility.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
import 'package:run_track/features/competitions/data/models/competition_result.dart';
import 'package:run_track/features/competitions/data/models/result_record.dart';

import '../core/models/activity.dart';
import '../core/services/activity_service.dart';
import '../features/competitions/data/services/competition_service.dart';
import '../features/notifications/data/models/notification.dart';
import '../features/notifications/data/services/notification_service.dart';
import 'config/app_data.dart';

// Future<void> generate30Competitions() async {
//   for (int i = 1; i <= 30; i++) {
//     final competition = Competition(
//       organizerUid: "Zf1wUzYIsGRCfyUxMrMdpOaBgR82", //FirebaseAuth.instance.currentUser?.uid ?? "",
//       name: "Test Competition $i",
//       description: "Auto-generated competition number $i",
//       createdAt: DateTime.now(),
//       startDate: DateTime.now().add(Duration(days: 1)),
//       endDate: DateTime.now().add(Duration(days: 7)),
//       registrationDeadline: DateTime.now().add(Duration(hours: 12)),
//       maxTimeToCompleteActivityHours: 2,
//       maxTimeToCompleteActivityMinutes: 30,
//       visibility: ComVisibility.everyone,
//       distanceToGo: 10.0 + i,
//       participantsUid: {FirebaseAuth.instance.currentUser?.uid ?? ""},
//       invitedParticipantsUid: {},
//       locationName: "Location $i",
//       location: LatLng(52.0 + i * 0.01, 21.0 + i * 0.01),
//       activityType: "running",
//       photos: [],
//       results: {},
//     );
//
//
//     final savedCompetition = await CompetitionService.saveCompetition(competition);
//
//     if (savedCompetition != null) {
//       AppData.instance.currentUser?.participatedCompetitions.add(savedCompetition.competitionId);
//       print("Saved competition: ${savedCompetition.competitionId}");
//     } else {
//       print("Failed to save competition $i");
//     }
//   }
//
//   print("=== 30 competitions created and saved ===");
// }

Future<void> generate100CompetitionRecords(String competitionId) async {
  if (competitionId.isEmpty) {
    print("Error: Competition ID cannot be empty.");
    return;
  }

  print("--- Generating 100 records for Competition ID: $competitionId ---");

  CompetitionResult result = CompetitionResult(competitionId: competitionId, ranking: []);

  for (int i = 1; i <= 100; i++) {
    final userUid = 'TestUser_$i';
    final userName = 'Runner_$i';

    int baseTimeMinutes = 60;
    int timeOffsetSeconds = (100 - i) * 10;
    int randomVariationSeconds = (i % 10) * 5;

    final totalTimeSeconds = baseTimeMinutes * 60 - timeOffsetSeconds + randomVariationSeconds;
    final runTime = Duration(seconds: totalTimeSeconds);

    final finished = (i % 10 != 0);

    final distance = finished ? 10.0 : 8.0 + (i % 2) * 0.5;

    final record = ResultRecord(
      userUid: userUid,
      firstName: userName,
      time: runTime,
      finished: finished,
      distance: distance,
      recordId: '',
      lastName: '',
    );

    try {
      await CompetitionService.addOrUpdateRecord(competitionId, record);
      if (i % 10 == 0) {
        print("Generated and saved ${i} records...");
      }
    } catch (e) {
      print("Failed to save record $i for $userName. Error: $e");
    }
  }

  print("=== 100 records successfully generated and added to ranking. ===");
}

Future<void> generate30Notifications() async {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? ""; // FirebaseAuth.instance.currentUser?.uid ?? "default_user";
  final now = DateTime.now();

  for (int i = 1; i <= 30; i++) {
    final type = (i % 2 == 0)
        ? NotificationType.inviteCompetition
        : NotificationType.inviteFriends;

    final title = (type == NotificationType.inviteCompetition)
        ? "You're invited to Test Competition $i"
        : "Friend Request from User $i";

    final notification = AppNotification(
      notificationId: "",
      uid: currentUid,
      title: title,
      type: type,
      objectId: "",
      createdAt: now.subtract(Duration(hours: 30 - i)),
      seen: (i % 5 == 0),
    );

    final savedNotification = await NotificationService.saveNotification(notification: notification);

    if (savedNotification != null) {
    } else {
      print("Failed to save notification $i");
    }
  }
  print("=== 30 notifications created and saved ===");
}

Future<void> generate30Competitions() async{
    final competition = Competition(
      organizerUid: FirebaseAuth.instance.currentUser?.uid ?? "",
      name: "Test Competition",
      description: "Auto-generated competition number",
      createdAt: DateTime.now(),
      startDate: DateTime.now().add(Duration(minutes: 1)),
      endDate: DateTime.now().add(Duration(days: 7)),
      registrationDeadline: DateTime.now().add(Duration(seconds: 4)),
      maxTimeToCompleteActivityHours: 2,
      maxTimeToCompleteActivityMinutes: 30,
      visibility: ComVisibility.everyone,
      distanceToGo: 1.0,
      participantsUid: {FirebaseAuth.instance.currentUser?.uid ?? ""},
      invitedParticipantsUid: {},
      locationName: "Location",
      location: LatLng(52.0  , 21.0),
      activityType: "running",
      photos: [],
      usersThatFinished: []
    );


    final savedCompetition = await CompetitionService.saveCompetition(competition);

}

