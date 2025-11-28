import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/core/enums/participant_management_action.dart';
import 'package:run_track/core/enums/user_action.dart';
import 'package:run_track/core/widgets/editable_profile_avatar.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';
import '../../app/navigation/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../enums/user_mode.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserSearcher extends SearchDelegate<Map<String, Set<String>?>> {
  UserMode userMode;
  final List<User> suggestedUsers = [];
  final ValueNotifier<int> rebuildNotifier = ValueNotifier(
    0,
  ); // Notifier to rebuild result list after sending a friend request

  UserSearcher({
    required this.userMode,
  });

  @override
  String? get searchFieldLabel => "Search users";

  @override
  TextStyle? get searchFieldStyle => TextStyle(color: Colors.white);

  Icon getIconForUser(String uid) {
    if (userMode == UserMode.friends &&  (AppData.instance.currentUser?.friends.contains(uid) ??  false) || userMode == UserMode.competitors && (AppData.instance.currentCompetition?.participantsUid.contains(uid) ?? false)) {
      return Icon(Icons.check, color: Colors.green); // Participate in or is on our friend list
    }
    if (userMode == UserMode.friends &&  (AppData.instance.currentUser?.pendingInvitationsToFriends.contains(uid) ??  false) ||  userMode == UserMode.competitors && (AppData.instance.currentCompetition?.invitedParticipantsUid.contains(uid) ?? false)) {
      return Icon(Icons.mail_outline, color: AppColors.secondary); // We send a request
    }
    if (userMode == UserMode.friends &&  (AppData.instance.currentUser?.receivedInvitationsToFriends.contains(uid) ??  false)) {
      return Icon(Icons.mark_email_unread, color: AppColors.secondary);
    }

    return Icon(Icons.person_add);
  }

  /// Add user uid to list
  void onPressedPersonAdd(String uid, BuildContext context) async {
    if(userMode == UserMode.friends && (AppData.instance.currentUser?.friends.contains(uid) ?? false)){
      return;
    }else if(userMode == UserMode.competitors && (AppData.instance.currentCompetition?.participantsUid.contains(uid) ?? false)){
      return;
    }

    if (userMode == UserMode.friends) {
      bool added = await UserService.manageUsers(
        senderUid: AppData.instance.currentUser?.uid ?? "",
        receiverUid: uid,
        action: UserAction.inviteToFriends,
      );
      if (added) {
        rebuildNotifier.value++;
        if(!context.mounted) return;

        showResults(context);
      }
    } else if (userMode == UserMode.competitors) {
      if (AppData.instance.currentCompetition != null) {
        // If it is empty it means we are creating competition
        bool added = await CompetitionService.manageParticipant(
          competitionId: AppData.instance.currentCompetition!.competitionId,
          targetUserId: uid,
          action: ParticipantManagementAction.invite,
        );

        if (added) {
          rebuildNotifier.value++;
          if(!context.mounted) return;
          showResults(context);
        }
      }
    }
  }

  /// Navigate to user profile and return list of users
  void onTapUser(BuildContext context, String uid) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'userMode': userMode, 'uid': uid},
    );

    rebuildNotifier.value++;
    if(!context.mounted) return;
    showResults(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty) // Clear query text
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  /// Leading buttons
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, {}));
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text("Enter a name to search"));
    }

    return ValueListenableBuilder(
      valueListenable: rebuildNotifier,
      builder: (context, value, child) {
        return FutureBuilder<List<User>>(
          future: UserService.searchUsers(
            query,
            exceptMe: true,
            myUid: FirebaseAuth.instance.currentUser?.uid ?? "",
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return Center(child: Text("No users found"));
            }
            final users = snapshot.data;

            if(users == null){
              return Center(child: Text("No users found"));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: SizedBox(
                    height: 40,
                    width: 40,
                    child: EditableProfileAvatar(
                      radius: 18,
                      currentPhotoUrl: user.profilePhotoUrl ?? '',
                    ),
                  ),
                  onTap: () => onTapUser(context, user.uid),
                  title: Text("${user.firstName} ${user.lastName}"),
                  trailing: IconButton(
                    onPressed: () => onPressedPersonAdd(user.uid, context),
                    icon: getIconForUser(user.uid),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: Colors.white54)),
      textTheme: TextTheme(titleLarge: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = suggestedUsers
        .where(
          (user) =>
              user.firstName.toLowerCase().contains(query.toLowerCase()) ||
              user.lastName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final user = suggestions[index];
        return ListTile(
          title: Text("${user.firstName} ${user.lastName}"),
          onTap: () => query = "${user.firstName} ${user.lastName}",
        );
      },
    );
  }
}
