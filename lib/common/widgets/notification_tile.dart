import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../theme/app_colors.dart';
import '../../theme/ui_constants.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const NotificationTile({super.key, required this.notification});

  IconData getIconForNotification() {
    switch (notification.type) {
      case NotificationType.inviteCompetition:
        return Icons.run_circle_outlined;
      case NotificationType.inviteFriends:
        return Icons.person;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.secondary,
      borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(getIconForNotification(), color: Colors.white),
            SizedBox(width: 7,),
            Text(notification.title, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
