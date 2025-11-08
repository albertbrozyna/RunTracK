import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/user_relationship.dart' show UserRelationshipStatus;
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/alert_dialog.dart';


class ProfileActionButton extends StatefulWidget {
  final UserRelationshipStatus userRelationshipStatus;
  final VoidCallback onPressedRemoveFriends;
  final VoidCallback onPressedRemoveInvitation;
  final VoidCallback onPressedSendInvitation;
  final VoidCallback onPressedAcceptInvitation;
  final VoidCallback onPressedDeclineInvitation;

  const ProfileActionButton({
    super.key,
    required this.userRelationshipStatus,
    required this.onPressedRemoveFriends,
    required this.onPressedRemoveInvitation,
    required this.onPressedSendInvitation,
    required this.onPressedAcceptInvitation,
    required this.onPressedDeclineInvitation,
  });

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  /// Logout button action
  void logoutButtonPressed(BuildContext context) {
    AppAlertDialog alert = AppAlertDialog(
      titleText: "Logout",
      contentText: "Are you sure you want to log out?",
      textLeft: "Cancel",
      textRight: "Log out",
      colorBackgroundButtonRight: AppColors.danger,
      colorButtonForegroundRight: AppColors.white,
      onPressedLeft: () {
        Navigator.of(context).pop();
      },
      onPressedRight: () {
        Navigator.of(context).pop();
        UserService.signOutUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out")));
        Navigator.of(context).pushNamedAndRemoveUntil('/start', (Route<dynamic> route) => false);
      },
    );

    showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by outside tap
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // TODO REFACTOR
  @override
  Widget build(BuildContext context) {
    if (widget.userRelationshipStatus == UserRelationshipStatus.myProfile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => logoutButtonPressed(context),
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.white, size: 26),

                Text("Logout", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          InkWell(
            onTap: () => {Navigator.pushNamed(context, '/settings')},
            child: Row(
              children: [
                Text("Settings", style: TextStyle(color: Colors.white)),
                Icon(Icons.settings, color: Colors.white, size: 26),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.userRelationshipStatus == UserRelationshipStatus.friend) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check_box, color: Colors.green, size: 26),
                ),
                Text("Friends", style: TextStyle(color: Colors.white)),
              ],
            ),

            InkWell(
              onTap: widget.onPressedRemoveFriends,
              child: Row(
                children: [
                  Text("Remove friend", style: TextStyle(color: Colors.white)),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.settings, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (widget.userRelationshipStatus == UserRelationshipStatus.pendingSent) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: () => (),
                    icon: Icon(Icons.hourglass_top, color: Colors.white, size: 26),
                  ),
                ),
                Text("Pending", style: TextStyle(color: Colors.white)),
              ],
            ),

            InkWell(
              onTap: widget.onPressedRemoveInvitation,
              child: Row(
                children: [
                  Text("Remove invitation", style: TextStyle(color: Colors.white)),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.remove, color: Colors.red, size: 26),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (widget.userRelationshipStatus == UserRelationshipStatus.pendingReceived) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: widget.onPressedDeclineInvitation,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, color: Colors.red, size: 26),
                  ),
                  Text("Decline", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            InkWell(
              onTap: widget.onPressedAcceptInvitation,
              child: Row(
                children: [
                  Text("Accept friend", style: TextStyle(color: Colors.green)),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.check, color: Colors.green, size: 26),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Add friend", style: TextStyle(color: Colors.white)),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: widget.onPressedSendInvitation,
              icon: Icon(Icons.person_add, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
