import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/common/enums/enter_context.dart';
import 'package:run_track/features/profile/pages/profile_page.dart';
import 'package:run_track/services/user_service.dart';

import '../../models/user.dart';
import '../../theme/colors.dart';

class UserSearcher extends SearchDelegate<List<String>?> {
  final List<String> invitedUsers;  // Invited to participate or to friends
  final List<String> listUsers; // Participants list or friends list
  EnterContextSearcher enterContext;
  final List<User>suggestedUsers = [];
  UserSearcher({required this.enterContext,required this.invitedUsers,required this.listUsers,});
  int _rebuildKey = 0;

  @override
  String? get searchFieldLabel => "Search users";

  @override
  TextStyle? get searchFieldStyle => TextStyle(color: Colors.white);


  Icon getIconForUser(String uid){
    if(listUsers.contains(uid)){
      return Icon(Icons.check, color: Colors.green); // Participate in or is on our friend list
    }
    if(invitedUsers.contains(uid)){
      return Icon(Icons.mail_outline, color: Colors.green); // Participate in or is on our friend list
    }

    return Icon(Icons.person_add);
  }

  /// Add user uid to list
  void onPressedPersonAdd(String uid,BuildContext context)async{
    if(enterContext == EnterContextSearcher.friends){
      bool added = await UserService.actionToUsers(FirebaseAuth.instance.currentUser?.uid ?? "", uid, UserAction.inviteToFriends);
      if (added) {
        invitedUsers.add(uid);
        ++_rebuildKey;
          showResults(context);
      }
    }else{
      invitedUsers.add(uid);
      showResults(context);
    }
  }

  /// Navigate to user profile
  void onTapUser(BuildContext context,String uid){
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfilePage(uid: uid)));
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
      onPressed: () => close(context,invitedUsers),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text("Enter a name to search"));
    }

    return FutureBuilder<List<User>>(
      key: ValueKey(_rebuildKey),
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
                    : AssetImage('assets/DefaultProfilePhoto.png') as ImageProvider,
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
