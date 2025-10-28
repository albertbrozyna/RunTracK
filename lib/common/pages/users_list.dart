import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/enums/enter_context.dart';
import 'package:run_track/common/widgets/no_items_msg.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/models/user.dart';

import '../../config/assets/app_images.dart';
import '../../features/track/widgets/fab_location.dart';
import '../widgets/searcher_users.dart';
import '../../services/user_service.dart';
import '../../theme/colors.dart';

class UsersList extends StatefulWidget {
  final Set<String> usersUid; // Friends for example or list of participants
  final Set<String> usersUid2; // For participants context it is list of invited
  final Set<String> usersUid3; // For friends it is list of invitations to friends
  final EnterContextUsersList enterContext;

  const UsersList({super.key, required this.usersUid, required this.usersUid2, required this.usersUid3, required this.enterContext});

  @override
  State<StatefulWidget> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  final List<User> _users = [];
  Set<String> _usersUid = {}; // List of participants
  Set<String> _usersUid2 = {}; // For participants context it is list of invited
  Set<String> _usersUid3 = {}; // For participants context it is list of invited
  bool visibleFabAdd = false;
  DocumentSnapshot? lastDocument;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Users per page
  bool _hasMore = true;
  bool _isLoading = false;
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

    if (widget.enterContext == EnterContextUsersList.participantsModify ||
        widget.enterContext == EnterContextUsersList.participantsReadOnly) {
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
    } else if (widget.enterContext == EnterContextUsersList.friendsModify) {
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
    }

    _usersUid = widget.usersUid;
    _usersUid2 = widget.usersUid2;
    _usersUid3 = widget.usersUid3;
  }

  /// Load my activities
  Future<void> _loadUsers() async {
    if (_isLoading == true || _hasMore == false) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final users = await UserService.fetchUsersListPage(uids: _usersUid, lastDocument: lastDocument, limit: _limit);

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
  void onPressedAddUsers() async {
    EnterContextSearcher enterContextSearcher = EnterContextSearcher.friends;
    if (widget.enterContext == EnterContextUsersList.participantsLookAndInvite) {
      enterContextSearcher = EnterContextSearcher.participants;
    }

    final result = await showSearch<Map<String,Set<String>?>>(
      context: context,
      delegate: UserSearcher(
        enterContext: enterContextSearcher,
        listUsers: _usersUid,
        invitedUsers: _usersUid2,
        receivedInvitations: _usersUid3,
      ),
    );

    if (result != null) {
      final Set<String>? usersUid = result['usersUid'];
      final Set<String>? usersUid2 = result['usersUid2'];
      final Set<String>? usersUid3 = result['usersUid3'];
      // Set invited participants
      setState(() {
        if(usersUid != null){
          _usersUid = usersUid;
        }
        if(usersUid2 != null){
          _usersUid2 = usersUid2;
        }
        if(usersUid3 != null){
          _usersUid3 = usersUid3;
        }
        _hasMore = false; // Reset users and fetch again
        UserService.lastFetchedDocumentParticipants = null;
        _users.clear();
        _loadUsers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => {
        if (!didPop)
          {
            Navigator.of(context).pop({'usersUid': _usersUid, 'usersUid2': _usersUid2, 'usersUid3': _usersUid3}),
          },
      },
      child: Scaffold(
        floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 120),
        floatingActionButton: Visibility(
          visible:
              widget.enterContext == EnterContextUsersList.participantsModify || widget.enterContext == EnterContextUsersList.friendsModify,
          child: FloatingActionButton(
            onPressed: onPressedAddUsers,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_add_alt_1, color: AppColors.white),
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
        body:PageContainer(
          assetPath: AppImages.appBg4,
          child: _users.isEmpty
              ? NoItemsMsg(textMessage: noItemsMessage)
              : ListView.builder(
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
