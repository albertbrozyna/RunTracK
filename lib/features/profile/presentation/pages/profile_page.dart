import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/enums/participant_management_action.dart';
import 'package:run_track/core/services/competition_service.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/enter_context.dart';
import '../../../../core/enums/user_mode.dart';
import '../../../../core/enums/user_relationship.dart';
import '../../../../core/models/competition.dart';
import '../../../../core/models/user.dart' as model;
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/content_container.dart';
import '../../../../core/widgets/no_items_msg.dart';
import '../../../../core/widgets/page_container.dart';
import '../../../../core/widgets/stat_card.dart';
import '../widgets/info_tile.dart';
import '../widgets/profile_action_button.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final UserMode userMode;

  const ProfilePage({
    super.key,
    required this.userMode,
    required this.uid,
  });

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final double cardHeight = 150;
  final double cardWidth = 150;
  String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  model.User? user;
  Competition? competition;
  UserRelationshipStatus relationshipStatus = UserRelationshipStatus.notConnected;

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    UserService.checkAppUseState(context);
  }

  /// Initialize async data
  Future<void> initializeAsync() async {
    // Load user data
    user = await UserService.fetchUser(widget.uid);

    // Check user relations and set status
    if (user != null && widget.userMode == UserMode.friends) {
      if (AppData.instance.currentUser?.friends.contains(widget.uid) ?? false) {
        relationshipStatus = UserRelationshipStatus.friend;
      } else if (AppData.instance.currentUser?.receivedInvitationsToFriends.contains(user!.uid) ??
          false) {
        relationshipStatus = UserRelationshipStatus.pendingReceived;
      } else if (AppData.instance.currentUser?.pendingInvitationsToFriends.contains(widget.uid) ??
          false) {
        relationshipStatus = UserRelationshipStatus.pendingSent;
      } else if (AppData.instance.currentUser?.uid == widget.uid) {
        relationshipStatus = UserRelationshipStatus.myProfile;
      }
    } else if (competition != null && widget.userMode == UserMode.competitors) {
      if (AppData.instance.currentCompetition?.invitedParticipantsUid.contains(widget.uid) ??
          false) {
        relationshipStatus = UserRelationshipStatus.competitionPendingSent;
      } else if (AppData.instance.currentCompetition?.participantsUid.contains(widget.uid) ??
          false) {
        relationshipStatus = UserRelationshipStatus.competitionParticipant;
      } else {
        relationshipStatus = UserRelationshipStatus.competitionNotConnected;
      }
    }

    setState(() {});
  }

  /// Invite to competition
  void onPressedInviteToCompetition() async {
    if (AppData.instance.currentCompetition != null && user != null) {
      bool success = await CompetitionService.manageParticipant(
        competitionId: AppData.instance.currentCompetition!.competitionId,
        targetUserId: user!.uid,
        action: ParticipantManagementAction.invite,
      );
      if (mounted && !success) {
        AppUtils.showMessage(context, "Error accepting invitation", messageType: MessageType.error);
      }
    }
  }

  /// Remove competitor
  void onPressedRemoveCompetitor()async {
    if (AppData.instance.currentCompetition != null && user != null) {
      bool success = await CompetitionService.manageParticipant(
        competitionId: AppData.instance.currentCompetition!.competitionId,
        targetUserId: user!.uid,
        action: ParticipantManagementAction.kick,
      );
      if (mounted && !success) {
        AppUtils.showMessage(context, "Error kicking competitor", messageType: MessageType.error);
      }
    }

  }

  /// Remove competitor
  void onPressedRemoveInvitationToCompetition() async {
    if (AppData.instance.currentCompetition != null && user != null) {
      bool success = await CompetitionService.manageParticipant(
        competitionId: AppData.instance.currentCompetition!.competitionId,
        targetUserId: user!.uid,
        action: ParticipantManagementAction.cancelInvitation,
      );
      if (mounted && !success) {
        AppUtils.showMessage(context, "Error removing invitation", messageType: MessageType.error);
      }
    }
  }

  /// Accept invitation
  void onPressedAcceptInvitationToFriends() async {
    bool success = await UserService.manageUsers(
      senderUid: myUid,
      receiverUid: user!.uid,
      action: UserAction.acceptInvitationToFriends,
    );
    if (mounted && !success) {
      AppUtils.showMessage(context, "Error accepting invitation", messageType: MessageType.error);
    }
  }

  /// Decline invitation
  void onPressedDeclineInvitationToFriends() async {
    bool success = await UserService.manageUsers(
      senderUid: myUid,
      receiverUid: user!.uid,
      action: UserAction.declineInvitationToFriends,
    );
    if (!success && mounted) {
      AppUtils.showMessage(context, "Error declining invitation", messageType: MessageType.error);
    }
  }

  /// Invite to friends
  void onPressedAddFriend() async {
    bool success = await UserService.manageUsers(
      senderUid: myUid,
      receiverUid: user!.uid,
      action: UserAction.inviteToFriends,
    );
    if (mounted && !success) {
      AppUtils.showMessage(context, "Error sending invitation", messageType: MessageType.error);
    }
  }

  /// Remove invite to friends
  void onPressedRemoveInviteToFriends() async {
    bool success = await UserService.manageUsers(
      senderUid: myUid,
      receiverUid: user!.uid,
      action: UserAction.removeInvitation,
    );
    if (mounted && !success ) {
      AppUtils.showMessage(context, "Error removing invitation", messageType: MessageType.error);
    }
  }

  void onPressedDeleteFriend() async {
    bool success = await UserService.manageUsers(
      senderUid: myUid,
      receiverUid: user!.uid,
      action: UserAction.deleteFriend,
    );

    if (mounted && !success) {
      AppUtils.showMessage(context, "Error deleting friend", messageType: MessageType.error);
    }
  }

  /// Show friends list
  void onTapFriends() async {
    EnterContextUsersList enterContext = EnterContextUsersList.friendReadOnly;
    if (relationshipStatus == UserRelationshipStatus.myProfile) {
      enterContext = EnterContextUsersList.friendsModify;
    }
    await Navigator.pushNamed(context, AppRoutes.usersList,
      arguments: {'enterContext': enterContext, 'users': user?.friends ?? <String>{}},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return NoItemsMsg(textMessage: "No user data");
    }

    return Scaffold(
      appBar: !(relationshipStatus == UserRelationshipStatus.myProfile)
          ? AppBar(title: Text("Profile"))
          : null,
      body: PageContainer(
        assetPath: AppImages.appBg4,
        backgroundColor: Colors.white60,
        padding: 0,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  color: AppColors.secondary,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20.0, right: 20.0),
                  child: ProfileActionButton(
                    userRelationshipStatus: relationshipStatus,
                    onPressedRemoveFriends: onPressedDeleteFriend,
                    onPressedRemoveInvitationToFriends: onPressedRemoveInviteToFriends,
                    onPressedSendInvitationToFriends: onPressedAddFriend,
                    onPressedAcceptInvitationToFriends: onPressedAcceptInvitationToFriends,
                    onPressedDeclineInvitationToFriends: onPressedDeclineInvitationToFriends,
                    onPressedSendInvitationToCompetition: onPressedInviteToCompetition,
                    onPressedRemoveInvitationToCompetition: onPressedRemoveInvitationToCompetition,
                    onPressedRemoveCompetitor: onPressedRemoveCompetitor,
                  ),
                ),
              ),
              SizedBox(height: AppUiConstants.verticalSpacingButtons),

              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3, style: BorderStyle.solid),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppImages.defaultProfilePhoto,
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.width / 2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Name and last name
              SizedBox(height: AppUiConstants.verticalSpacingButtons),

              // Friend list
              ContentContainer(
                borderRadius: 30,
                backgroundColor: AppColors.secondary,
                child: Column(
                  children: [
                    ListInfoTile(icon: Icons.person, title: "${user?.firstName} ${user?.lastName}"),
                    ListInfoTile(icon: Icons.email, title: "${user?.email}"),
                    ListInfoTile(
                      icon: user!.gender! == 'male' ? Icons.male : Icons.female,
                      title: "${user?.gender}",
                    ),
                    ListInfoTile(
                      icon: Icons.cake,
                      title: AppUtils.formatDateTime(user?.dateOfBirth, onlyDate: true),
                    ),
                    ListInfoTile(
                      icon: Icons.card_membership,
                      title:
                          "Member since: ${AppUtils.formatDateTime(user?.createdAt, onlyDate: true)}",
                    ),
                    InkWell(
                      onTap: onTapFriends,
                      child: ListInfoTile(
                        icon: Icons.people,
                        title: "Friends: ${user!.friends.length.toString()}",
                        endDivider: false,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppUiConstants.verticalSpacingButtons),
              ContentContainer(
                borderRadius: 30,
                backgroundColor: AppColors.secondary,
                child: Column(
                  children: [
                    Text(
                      "Activity & Stats",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: AppUiConstants.verticalSpacingButtons),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        InkWell(
                          onTap: onTapFriends,
                          child: StatCard(
                            title: "Created\ncompetitions",
                            value: user?.competitionsCount.toString() ?? 'Unknown',
                            icon: Icon(Icons.run_circle_outlined),
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                          ),
                        ),
                        InkWell(
                          onTap: onTapFriends,
                          child: StatCard(
                            title: "Activities",
                            value: user!.activitiesCount.toString(),
                            icon: Icon(Icons.run_circle_outlined),
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                          ),
                        ),

                        StatCard(
                          title: "Total\ndistance",
                          value: "${user!.kilometers.toString()} km",
                          icon: Icon(Icons.directions_run),
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),

                        StatCard(
                          title: "Total hours\nof activity",
                          value: "${user!.hoursOfActivity.toString()} h",
                          icon: Icon(Icons.timer),
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),

                        StatCard(
                          title: "Burned\ncalories",
                          value: "${user!.burnedCalories.toString()} kcal",
                          icon: Icon(Icons.timer),
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
