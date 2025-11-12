import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/core/enums/participant_management_action.dart';
import 'package:run_track/core/services/competition_service.dart';
import '../../app/config/app_images.dart';
import '../../app/navigation/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../enums/enter_context.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserSearcher extends SearchDelegate<Map<String,Set<String>?>> {
  final Set<String> listUsers; // Participants list or friends list
  final Set<String> invitedUsers;  // Invited to participate or to friends
  final Set<String> receivedInvitations; // Participants list or friends list
  EnterContextSearcher enterContext;
  String competitionId;
  final List<User>suggestedUsers = [];
  UserSearcher({required this.enterContext,required this.invitedUsers,required this.listUsers,required this.receivedInvitations,required this.competitionId});
  final ValueNotifier<int> rebuildNotifier = ValueNotifier(0);  // Notifier to rebuild result list after sending a friend request

  @override
  String? get searchFieldLabel => "Search users";

  @override
  TextStyle? get searchFieldStyle => TextStyle(color: Colors.white);


  Icon getIconForUser(String uid){
    if(listUsers.contains(uid)){
      return Icon(Icons.check, color: Colors.green); // Participate in or is on our friend list
    }
    if(invitedUsers.contains(uid)){
      return Icon(Icons.mail_outline, color:AppColors.secondary); // We send a request
    }
    if(receivedInvitations.contains(uid)) {
      return Icon(Icons.mark_email_unread, color: AppColors.secondary);
    }

    return Icon(Icons.person_add);
  }

  /// Add user uid to list
  void onPressedPersonAdd(String uid,BuildContext context)async{
    if(listUsers.contains(uid) || invitedUsers.contains(uid) || receivedInvitations.contains(uid)){  // We can't do action from this look
      showResults(context);
      return;
    }

    if(enterContext == EnterContextSearcher.friends){
      bool added = await UserService.actionToUsers(FirebaseAuth.instance.currentUser?.uid ?? "", uid, UserAction.inviteToFriends);
      if (added) {
        invitedUsers.add(uid);
        rebuildNotifier.value++;
        showResults(context);
      }
    }else if(enterContext == EnterContextSearcher.participants){
      bool added = await CompetitionService.manageParticipant(competitionId: competitionId,targetUserId: uid,action: ParticipantManagementAction.invite );
      if(added){
        invitedUsers.add(uid);
        rebuildNotifier.value++;
        showResults(context);
      }
    }
  }

  /// Navigate to user profile and return list of users
  void onTapUser(BuildContext context,String uid) async {
    final result = await Navigator.pushNamed(context, AppRoutes.profile,arguments: {  // Navigate to profile and pass this list
      'uid': uid,
      'usersList': listUsers,
      'invitedUsers': invitedUsers,
      'receivedInvites': receivedInvitations,
    });

    if(result != null && result is Map){
      final Set<String> usersUid = (result['usersUid'] as Set<String>?) ?? {};
      final Set<String> usersUid2 = (result['usersUid2'] as Set<String>?) ?? {};
      final Set<String> usersUid3 = (result['usersUid3'] as Set<String>?) ?? {};
      // Set invited participants
      listUsers.clear();
      listUsers.addAll(usersUid);
      invitedUsers.clear();
      invitedUsers.addAll(usersUid2);
      receivedInvitations.clear();
      receivedInvitations.addAll(usersUid3);
      rebuildNotifier.value++;
    }
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
    return IconButton(  // Return with invited users
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context,{
        'usersUid': listUsers,
        'usersUid2': invitedUsers,
        'usersUid3': receivedInvitations,
      }),
    );
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
          future: UserService.searchUsers(query,exceptMe: true,myUid: FirebaseAuth.instance.currentUser?.uid ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return Center(child: Text("No users found"));
            }
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                        ? NetworkImage(user.profilePhotoUrl!)
                        : AssetImage(AppImages.defaultProfilePhoto) as ImageProvider,
                  ),
                  onTap: () => onTapUser(context, user.uid),
                  title: Text("${user.firstName} ${user.lastName}"),
                  trailing: IconButton(onPressed: () => onPressedPersonAdd(user.uid,context), icon: getIconForUser(user.uid)),
                );
              },
            );
          },
        );
      }
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  // TODO add a
  Widget buildSuggestions(BuildContext context) {
    final suggestions = suggestedUsers
        .where((user) =>
    user.firstName.toLowerCase().contains(query.toLowerCase()) ||
        user.lastName.toLowerCase().contains(query.toLowerCase()))
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
