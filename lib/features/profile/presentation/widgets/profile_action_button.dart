import 'package:flutter/material.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';
import 'package:run_track/features/track/data/services/track_foreground_service.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/user_relationship.dart' show UserRelationshipStatus;
import '../../../../core/widgets/alert_dialog.dart';

class ProfileActionButton extends StatefulWidget {
  final UserRelationshipStatus userRelationshipStatus;
  final VoidCallback onPressedRemoveFriends;
  final VoidCallback onPressedRemoveInvitationToFriends;
  final VoidCallback onPressedSendInvitationToFriends;
  final VoidCallback onPressedAcceptInvitationToFriends;
  final VoidCallback onPressedDeclineInvitationToFriends;
  final VoidCallback onPressedSendInvitationToCompetition;
  final VoidCallback onPressedRemoveInvitationToCompetition;
  final VoidCallback onPressedRemoveCompetitor;
  final VoidCallback navigateToSettings;

  const ProfileActionButton({
    super.key,
    required this.userRelationshipStatus,
    required this.onPressedRemoveFriends,
    required this.onPressedRemoveInvitationToFriends,
    required this.onPressedSendInvitationToFriends,
    required this.onPressedAcceptInvitationToFriends,
    required this.onPressedDeclineInvitationToFriends,
    required this.onPressedSendInvitationToCompetition,
    required this.onPressedRemoveInvitationToCompetition,
    required this.onPressedRemoveCompetitor,
    required this.navigateToSettings,
  });

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {

  bool _isLoggingOut = false;

  void logoutButtonPressed(BuildContext context) async {
    if(_isLoggingOut){
      return;
    }
    _isLoggingOut = true;
    bool isServiceRunning = await ForegroundTrackService.instance.isServiceRunning();

    if(!mounted){
      _isLoggingOut = false;
      return;
    }
    if(isServiceRunning){
      if(!context.mounted){
        _isLoggingOut = false;
        return;
      }
      AppUtils.showMessage(context, "You cannot log out when tracking service is running!",messageType: MessageType.error);
      _isLoggingOut = false;
      return;
    }

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
        AuthService.instance.signOutUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out")));
        Navigator.of(context).pushNamedAndRemoveUntil('/start', (Route<dynamic> route) => false);
      },
    );

    if(!context.mounted){
      _isLoggingOut = false;
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return alert;
      },
    );
    _isLoggingOut = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRelationshipStatus == UserRelationshipStatus.myProfile) {
      return _buildMyProfile(context);
    }

    final Widget childRow;

    switch (widget.userRelationshipStatus) {
      case UserRelationshipStatus.friend:
        childRow = _buildFriend(context);
        break;
      case UserRelationshipStatus.pendingSent:
        childRow = _buildPendingSent(context);
        break;
      case UserRelationshipStatus.pendingReceived:
        childRow = _buildPendingReceived(context);
        break;

      case UserRelationshipStatus.competitionParticipant:
        childRow = _buildCompetitor(context);
        break;
      case UserRelationshipStatus.competitionPendingSent:
        childRow = _buildCompetitionPendingSent(context);
        break;
      case UserRelationshipStatus.competitionNotConnected:
        childRow = _buildNotCompetitor(context);
        break;
      default:
        childRow = _buildNotFriend(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: childRow,
    );
  }

  Widget _buildMyProfile(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => logoutButtonPressed(context),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 5.0),
                child: Icon(Icons.logout, color: Colors.white, size: 26),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 5.0),
                child: Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.navigateToSettings,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 5.0),
                child: Text("Settings", style: TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 5.0),
                child: Icon(Icons.settings, color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 5.0),
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
                padding: const EdgeInsets.only(right: 8.0, left: 5),
                child: Icon(Icons.person_remove_sharp, color: AppColors.danger, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingSent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 5.0),
              child: Icon(Icons.hourglass_top, color: Colors.white, size: 26),
            ),

              Text("Pending", style: TextStyle(color: Colors.white)),

          ],
        ),
        InkWell(
          onTap: widget.onPressedRemoveInvitationToFriends,
          child: Row(
            children: [
              Text("Remove invitation", style: TextStyle(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(left: 5.0,right: 8.0),
                child: Icon(Icons.cancel_schedule_send, color: Colors.red, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingReceived(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: widget.onPressedDeclineInvitationToFriends,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0,right: 5.0),
                child: Icon(Icons.close, color: Colors.red, size: 26),
              ),
              Text("Decline", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        InkWell(
          onTap: widget.onPressedAcceptInvitationToFriends,
          child: Row(
            children: [
              Text("Accept friend", style: TextStyle(color: Colors.green)),
              Padding(
                padding: const EdgeInsets.only(left: 5.0,right: 8.0),
                child: Icon(Icons.check, color: Colors.green, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFriend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Add friend", style: TextStyle(color: Colors.white)),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: widget.onPressedSendInvitationToFriends,
            icon: Icon(Icons.person_add, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitor(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0,right: 5.0),
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 26),
            ),
            Text("Competitor", style: TextStyle(color: Colors.white)),
          ],
        ),
        InkWell(
          onTap: widget.onPressedRemoveCompetitor,
          child: Row(
            children: [
              Text("Remove competitor", style: TextStyle(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(left: 5.0,right: 8.0),
                child: Icon(Icons.emoji_events_rounded, color: Colors.red, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionPendingSent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0,right: 5.0),
              child: Icon(Icons.hourglass_top_sharp, color: Colors.white, size: 26),
            ),
            Text("Pending", style: TextStyle(color: Colors.white)),
          ],
        ),
        InkWell(
          onTap: widget.onPressedRemoveInvitationToCompetition,
          child: Row(
            children: [
              Text("Remove invitation", style: TextStyle(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(left: 5.0,right: 8.0),
                child: Icon(Icons.cancel_schedule_send, color: Colors.red, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotCompetitor(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Add to competition", style: TextStyle(color: Colors.white)),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: widget.onPressedSendInvitationToCompetition,
            icon: Icon(Icons.playlist_add, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}
