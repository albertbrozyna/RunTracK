import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/enums/enter_context.dart';
import 'package:run_track/common/widgets/no_items_msg.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/models/user.dart';

import '../../features/track/widgets/fab_location.dart';
import '../widgets/searcher_users.dart';
import '../../services/user_service.dart';
import '../../theme/colors.dart';


class UsersList extends StatefulWidget{
  final List<String> usersUid;
  final List<String> usersUid2;
  final EnterContextUsersList enterContext;
  const UsersList({super.key,required this.usersUid,required this.usersUid2,required this.enterContext});

  @override
  State<StatefulWidget> createState() => _UsersListState();
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

  String pageTitle = "";
  String noItemsMessage = "";

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
      return;
    }

    if(widget.enterContext == EnterContextUsersList.participantsModify || widget.enterContext ==  EnterContextUsersList.participantsReadOnly){
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
    }else if(widget.enterContext == EnterContextUsersList.friendsModify){
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
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

    final users = await UserService.fetchUsersListPage(
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
    EnterContextSearcher enterContextSearcher = EnterContextSearcher.friends;
    if(widget.enterContext == EnterContextUsersList.participantsLookAndInvite){
      enterContextSearcher = EnterContextSearcher.participants;
    }

    final selectedUsers = await showSearch<List<String>?>(
      context: context,
      delegate: UserSearcher(enterContext: enterContextSearcher, listUsers: _usersUid,invitedUsers: _usersUid2),
    );

    if (selectedUsers != null) {  // Assign invited users
      setState(() {
        _usersUid2.clear();
        _usersUid2.addAll(selectedUsers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => {
        if (!didPop) {
          Navigator.of(context).pop({'usersUid': _usersUid,
          'usersUid2': _usersUid2}),
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 120),
        floatingActionButton: Visibility(
          visible: widget.enterContext == EnterContextUsersList.participantsModify || widget.enterContext == EnterContextUsersList.friendsModify,
          child: FloatingActionButton(
            onPressed: onPressedAddUsers,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_add_alt_1,color: AppColors.white,),
          ),
        ),
        appBar: AppBar(
          title: Text(
            pageTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body:   Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/appBg6.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken),
            ),
          ),
          padding: EdgeInsets.only(top: 10),
          child: _users.isEmpty ? NoItemsMsg(textMessage: noItemsMessage) : ListView.builder(
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
      ),
    );
  }

}