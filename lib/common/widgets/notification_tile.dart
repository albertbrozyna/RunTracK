import 'package:flutter/material.dart';
import '';
import '../../models/notification.dart';

class NotificationTile extends StatelessWidget {
  AppNotification notification;

  NotificationTile({super.key, required this.notification});


  IconData getIconForNotification(){
    switch(notification.type){
      case NotificationType.inviteCompetition:
        return Icons.run_circle_outlined;
      case NotificationType.inviteFriends:
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: Row(children: [Icon(getIconForNotification()), Text(notification.title)]));
  }
}
