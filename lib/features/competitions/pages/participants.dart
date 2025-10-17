import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/enums/enter_context_users_list.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/models/user.dart';

import '../../../common/widgets/seacher_users.dart';
import '../../../services/user_service.dart';
import '../../../theme/colors.dart';




class UsersList extends StatefulWidget{
  final List<String> usersUid;
  final List<String> usersUid2;
  final EnterContextUsersList enterContext;
  const UsersList({super.key,required this.usersUid,required this.usersUid2,required this.enterContext});

  @override
  State<StatefulWidget> createState() {
    return _UsersListState();
  }
}

class _UsersListState extends State<UsersList>{
  final List<User> _users = [];
  List<String> _usersUid = [];  // List of participants
  List<String> _usersUid2 = []; // For participants context it is list of invited
  bool visibleFabAdd = false;
  DocumentSnapshot? lastDocument;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Users per page
  bool _hasMore = true;
  bool _isLoading = false;
  late List<String> usersUid;

  @override
  void initState() {
    super.initState();
    initialize();
    _loadUsers();
  }

  void initialize() {
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
    }
    _usersUid = widget.usersUid;
    _usersUid2 = widget.usersUid2;
  }

  /// Load my activities
  Future<void> _loadUsers() async {
    if (_isLoading == true || _hasMore == false) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final users = await UserService.fetchInvitedParticipants(
      uids: usersUid,
      lastDocument: lastDocument,
      limit: _limit,
    );

    setState(() {
      _users.addAll(users);
      lastDocument = users.isNotEmpty ? UserService.lastFetchedDocumentParticipants : null;
      _isLoading = false;
      if (users.length < _limit) {
        _hasMore = false;
      }
    });
  }

  /// On pressed button add users
  void onPressedAddUsers()async {
    final selectedUsers = await showSearch<List<String>?>(
      context: context,
      // TODO add
      delegate: UserSearcher(listUsers: _usersUid,invitedUsers: _usersUid2),
    );

    if (selectedUsers != null) {
      setState(() {
        _usersUid2.clear();
        _usersUid2.addAll(selectedUsers);
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
        visible: widget.enterContext == EnterContextUsersList.participantsModify,
        child: FloatingActionButton(
          onPressed: onPressedAddUsers,
          child: Icon(Icons.add),
        ),
      ),
      appBar: AppBar(
        title: Text(
          "Participants",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.search, color: Colors.white),
        //     onPressed: () {
        //         onPressedSearch();
        //     },
        //   ),
        // ],
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body:   Container(
        padding: EdgeInsets.only(top: 10),
        child: _users.isEmpty ? Center(child: Text("No participants found")) : ListView.builder(
          controller: _scrollController,
          itemCount: _users.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _users.length) {
              return Center(child: CircularProgressIndicator());
            }
            final user = _users[index];
            return UserProfileTile(key: ValueKey(user.uid), firstName: user.firstName, lastName: user.lastName);
          },
        ),
      ),
    );
  }

}