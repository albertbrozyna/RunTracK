import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/enums/visibility.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';

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
      notificationId: "", // Zostanie ustawione przez serwis
      uid: currentUid,
      title: title,
      type: type,
      objectId: "",
      createdAt: now.subtract(Duration(hours: 30 - i)), // Rozłóż czas utworzenia
      seen: (i % 5 == 0), // Ustaw niektóre jako "widziane"
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
      notificationId: "", // Zostanie ustawione przez serwis
      uid: currentUid,
      title: title,
      type: type,
      objectId: "",
      createdAt: now.subtract(Duration(hours: 30 - i)), // Rozłóż czas utworzenia
      seen: (i % 5 == 0), // Ustaw niektóre jako "widziane"
    );

    final savedNotification = await NotificationService.saveNotification(notification:  notification);

    if (savedNotification != null) {
    } else {
      print("Failed to save notification $i");
    }
  }
  print("=== 30 notifications created and saved ===");

}

