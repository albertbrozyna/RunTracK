import 'package:flutter/material.dart';

import '../../app/config/app_data.dart';
import '../../app/config/app_images.dart';
import '../../app/navigation/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../features/track/presentation/widgets/fab_location.dart';
import '../enums/enter_context.dart' show EnterContextUsersList, EnterContextSearcher;
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/no_items_msg.dart';
import '../widgets/page_container.dart';
import '../widgets/searcher_users.dart';
import '../widgets/user_profile_list.dart';



class UsersList extends StatefulWidget {
  final List<String> usersList;  // List of user
  final EnterContextUsersList enterContext;
  final String competitionId;

  const UsersList({super.key,required this.enterContext});

  @override
  State<StatefulWidget> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Users per page
  final List<User> _users = [];
  List<String> _usersUid = [];
  bool visibleFabAdd = false;
  String? lastUid; // Last uid for pagination
  bool _hasMore = true;
  bool _isLoading = false;
  String pageTitle = "";
  String noItemsMessage = "";


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    UserService.checkAppUseState(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        _loadUsers();
      }
    });

    if(widget.enterContext == EnterContextUsersList.friendsModify){
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
      _usersUid = AppData.instance.currentUser?.friends.toList() ?? []; // My friends
    }else if(widget.enterContext == EnterContextUsersList.friendReadOnly){
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
      _usersUid = widget.usersList; // Another profile friends
    }else if(widget.enterContext == EnterContextUsersList.participantsModify){
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
      _usersUid = AppData.instance.currentCompetition?.participantsUid.toList() ?? [];  // Competitors
    }else if(widget.enterContext == EnterContextUsersList.participantsReadOnly){
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
      _usersUid = widget.usersList;  // Competitors
    }
    _loadUsers();
  }

  /// Load users
  Future<void> _loadUsers() async {
    if (_isLoading == true || _hasMore == false) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    int index = 0;
    if (lastUid != null) {
      index = _usersUid.indexOf(lastUid!);

      if (index == -1 || index == _usersUid.length - 1) {
        _hasMore = false;
        return;
      }
      index++;
    }
    int end = (index + _limit > _usersUid.length) ? _usersUid.length : index + _limit;

    List<String> usersSlice = _usersUid.sublist(index, end);

    final users = await UserService.fetchUsers(uids: usersSlice, limit: _limit);

    setState(() {
      _users.addAll(users);
      lastUid = users.isNotEmpty ? users.last.uid : null;
      _isLoading = false;
      if (users.length < _limit) {
        _hasMore = false;
      }
    });
  }

  /// On pressed button add users
  void onPressedAddUsers() async {
    EnterContextSearcher enterContextSearcher = EnterContextSearcher.friends;
    if (widget.enterContext == EnterContextUsersList.participantsModify) {
      enterContextSearcher = EnterContextSearcher.participants;
    }

    final result = await showSearch<Map<String, Set<String>?>>(
      context: context,
      delegate: UserSearcher(
        enterContext: enterContextSearcher,
        listUsers: _usersUid.toSet(),
        invitedUsers: _usersUid2.toSet(),
        receivedInvitations: _usersUid3.toSet(),
        competitionId: widget.competitionId
      ),
    );

    if (result != null) {
      final Set<String>? usersUid = result['usersUid'];
      final Set<String>? usersUid2 = result['usersUid2'];
      final Set<String>? usersUid3 = result['usersUid3'];
      // Set invited participants
      setState(() {
        if (usersUid != null) {
          _usersUid = usersUid.toList();
        }
        if (usersUid2 != null) {
          _usersUid2 = usersUid2.toList();
        }
        if (usersUid3 != null) {
          _usersUid3 = usersUid3.toList();
        }
        // Reset users and fetch again with new users
        _hasMore = true;
        lastUid = null;
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
            Navigator.of(context).pop({'usersUid': _usersUid.toSet(), 'usersUid2': _usersUid2.toSet(), 'usersUid3': _usersUid3.toSet()}),
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
        body: PageContainer(
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
