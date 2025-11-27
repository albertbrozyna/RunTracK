import 'package:flutter/material.dart';
import 'package:run_track/core/utils/utils.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../data/models/notification.dart';

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

      decoration: BoxDecoration(
        color:  AppColors.secondary,
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary,
          blurStyle: BlurStyle.outer,
          offset: Offset(0, 0),
          blurRadius: 8.0
        )
      ],
      borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(getIconForNotification(), color: Colors.white),
                SizedBox(width: 7,),
                Expanded(child: Text(notification.title, style: TextStyle(color: Colors.white))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 15.0,),
              Expanded(child: Text("Created at: ${AppUtils.formatDateTime(notification.createdAt)}" , style: TextStyle(color: Colors.white,fontSize: 12.0))),
            ],)
          ],
        ),
      ),
    );
  }
}
