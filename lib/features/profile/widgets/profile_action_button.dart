import 'package:flutter/material.dart';
import 'package:run_track/common/enums/user_relationship.dart';

import '../../../theme/colors.dart';

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

class _ProfileActionButtonState extends State<ProfileActionButton>
{

  @override
  Widget build(BuildContext context) {
    if (widget.userRelationshipStatus == UserRelationshipStatus.myProfile) {
      return SizedBox(height: 1);
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
