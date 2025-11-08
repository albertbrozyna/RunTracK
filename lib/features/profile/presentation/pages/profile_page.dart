import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/enter_context.dart';
import '../../../../core/enums/user_relationship.dart';
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
  final String? uid; // uid of the user which we need to show a profile
  final model.User? passedUser; // Data of user which we are showing
  final Set<String> usersList;
  final Set<String> invitedUsers;
  final Set<String> receivedInvites;

  const ProfilePage({
    super.key,
    this.uid,
    this.passedUser,
    this.usersList = const {},
    this.invitedUsers = const {},
    this.receivedInvites = const {},
  });

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final double cardHeight = 150;
  final double cardWidth = 150;

  late Set<String> usersList;
  late Set<String> invitedUsers;
  late Set<String> receivedInvitations;
  model.User? user; // User which we are showing
  UserRelationshipStatus relationshipStatus =
      UserRelationshipStatus.notConnected;

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    UserService.checkAppUseState(context);

    usersList = Set.from(widget.usersList);
    invitedUsers = Set.from(widget.invitedUsers);
    receivedInvitations = Set.from(widget.receivedInvites);
  }

  /// Initialize async data
  Future<void> initializeAsync() async {
    // Load user data
    if (widget.uid != null) {
      user = await UserService.fetchUser(widget.uid!);
    }



    if (user != null) {
      // Check user relationship
      if (user!.friendsUid.contains(AppData.instance.currentUser?.uid)) {
        relationshipStatus = UserRelationshipStatus.friend;
      } else if (AppData.instance.currentUser?.receivedInvitationsToFriends.contains(
            user!.uid,
          ) ??
          false) {
        relationshipStatus = UserRelationshipStatus.pendingReceived;
      } else if (AppData.instance.currentUser?.pendingInvitationsToFriends.contains(
            user!.uid,
          ) ??
          false) {
        relationshipStatus = UserRelationshipStatus.pendingSent;
      } else if (user!.uid == AppData.instance.currentUser?.uid) {
        relationshipStatus = UserRelationshipStatus.myProfile;
      }
    }

    setState(() {});
  }

  /// Accept invitation
  void onPressedAcceptInvitation() async {
    bool added = await UserService.actionToUsers(
      user!.uid,
      FirebaseAuth.instance.currentUser?.uid ?? "",
      UserAction.acceptInvitationToFriends,
    );
    if (added) {
      setState(() {
        usersList.add(user!.uid); // Add to friends or competitions
        receivedInvitations.remove(user!.uid);
        relationshipStatus = UserRelationshipStatus.friend;
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Error accepting invitation",
          messageType: MessageType.error,
        );
      }
    }
  }

  /// Decline invitation
  void onPressedDeclineInvitation() async {
    bool added = await UserService.actionToUsers(
      user!.uid,
      FirebaseAuth.instance.currentUser?.uid ?? "",
      UserAction.declineInvitationToFriends,
    );
    if (added) {
      setState(() {
        receivedInvitations.remove(user!.uid);
        relationshipStatus = UserRelationshipStatus.notConnected;
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Error declining invitation",
          messageType: MessageType.error,
        );
      }
    }
  }

  /// Invite to friends
  void onPressedAddFriend() async {
    bool added = await UserService.actionToUsers(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      user!.uid,
      UserAction.inviteToFriends,
    );
    if (added) {
      setState(() {
        relationshipStatus = UserRelationshipStatus.pendingSent;
        invitedUsers.add(user!.uid);
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Error sending invitation",
          messageType: MessageType.error,
        );
      }
    }
  }

  /// Remove invite to friends
  void onPressedRemoveInviteToFriends() async {
    bool added = await UserService.actionToUsers(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      user!.uid,
      UserAction.removeInvitation,
    );
    if (added) {
      setState(() {
        relationshipStatus = UserRelationshipStatus.notConnected;
        invitedUsers.remove(user!.uid);
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Error removing invitation",
          messageType: MessageType.error,
        );
      }
    }
  }

  void onPressedDeleteFriend() async {
    bool added = await UserService.actionToUsers(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      user!.uid,
      UserAction.deleteFriend,
    );
    if (added) {
      setState(() {
        relationshipStatus = UserRelationshipStatus.notConnected;
        usersList.remove(user!.uid);
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Error deleting friend",
          messageType: MessageType.error,
        );
      }
    }
  }

  /// Show friends list
  void onTapFriends() async {
    EnterContextUsersList enterContext = EnterContextUsersList.friendReadOnly;
    if (relationshipStatus == UserRelationshipStatus.myProfile) {
      enterContext = EnterContextUsersList.friendsModify;
    }
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.usersList,
      arguments: {
        'usersUid': user?.friendsUid ?? [],
        'usersUid2': user?.pendingInvitationsToFriends ?? [],
        'usersUid3': user?.receivedInvitationsToFriends ?? [],
        'enterContext': enterContext,
      },
    );

    // Set changes to current user if it me
    if (enterContext == EnterContextUsersList.friendsModify &&
        result != null &&
        result is Map) {
      final Set<String> usersUid = result['usersUid'];
      final Set<String> usersUid2 = result['usersUid2'];
      final Set<String> usersUid3 = result['usersUid3'];
      // Set invited participants
      setState(() {
        user?.friendsUid = usersUid;
        user?.pendingInvitationsToFriends = usersUid2;
        user?.receivedInvitationsToFriends = usersUid3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // No user data found
      return NoItemsMsg(textMessage: "No user data");
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => {
        if (!didPop)
          {
            Navigator.pop(context, {
              'usersUid': usersList,
              'usersUid2': invitedUsers,
              'usersUid3': receivedInvitations,
            }),
          },
      },
      child: Scaffold(
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
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: ProfileActionButton(
                      userRelationshipStatus: relationshipStatus,
                      onPressedRemoveFriends: onPressedDeleteFriend,
                      onPressedRemoveInvitation: onPressedRemoveInviteToFriends,
                      onPressedSendInvitation: onPressedAddFriend,
                      onPressedAcceptInvitation: onPressedAcceptInvitation,
                      onPressedDeclineInvitation: onPressedDeclineInvitation,
                    ),
                  ),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingButtons),

                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/DefaultProfilePhoto.png",
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
                      ListInfoTile(
                        icon: Icons.person,
                        title: "${user?.firstName} ${user?.lastName}",
                      ),
                      ListInfoTile(icon: Icons.email, title: "${user?.email}"),
                      ListInfoTile(
                        icon: user!.gender! == 'male'
                            ? Icons.male
                            : Icons.female,
                        title: "${user?.gender}",
                      ),
                      ListInfoTile(
                        icon: Icons.cake,
                        title: AppUtils.formatDateTime(
                          user!.dateOfBirth,
                          onlyDate: true,
                        ),
                      ),
                      ListInfoTile(
                        icon: Icons.card_membership,
                        title:
                            "Member since: ${AppUtils.formatDateTime(user!.createdAt, onlyDate: true)}",
                      ),
                      InkWell(
                        onTap: onTapFriends,
                        child: ListInfoTile(
                          icon: Icons.people,
                          title:
                              "Friends: ${user!.friendsUid.length.toString()}",
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
                              value: user!.competitionsCount.toString(),
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
      ),
    );
  }
}
