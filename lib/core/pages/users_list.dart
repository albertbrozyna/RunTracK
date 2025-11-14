import 'package:flutter/material.dart';
import 'package:run_track/core/enums/user_mode.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../app/config/app_data.dart';
import '../../app/config/app_images.dart';
import '../../app/navigation/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../features/track/presentation/widgets/fab_location.dart';
import '../enums/enter_context.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/no_items_msg.dart';
import '../widgets/page_container.dart';
import '../widgets/searcher_users.dart';
import '../widgets/user_profile_list.dart';

class UsersList extends StatefulWidget {
  final List<String> users; // List of user
  final EnterContextUsersList enterContext;

  const UsersList({super.key, required this.enterContext, required this.users});

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
    AuthService.instance.checkAppUseState(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        _loadUsers();
      }
    });

    if (widget.enterContext == EnterContextUsersList.friendsModify) {
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
      _usersUid = AppData.instance.currentUser?.friends.toList() ?? []; // My friends
    } else if (widget.enterContext == EnterContextUsersList.friendReadOnly) {
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
      _usersUid = widget.users; // Another profile friends
    } else if (widget.enterContext == EnterContextUsersList.participantsModify) {
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
      _usersUid =
          AppData.instance.currentCompetition?.participantsUid.toList() ?? []; // Competitors
    } else if (widget.enterContext == EnterContextUsersList.participantsReadOnly) {
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
      _usersUid = widget.users; // Competitors
    }
    _loadUsers();
  }

  void updateList() {
    if (widget.enterContext == EnterContextUsersList.friendsModify) {
      _usersUid = AppData.instance.currentUser?.friends.toList() ?? [];
    } else if (widget.enterContext == EnterContextUsersList.participantsModify) {
      _usersUid = AppData.instance.currentCompetition?.participantsUid.toList() ?? [];
    }

    setState(() {
      _users.clear();
      lastUid = null;
      _hasMore = true;
      _isLoading = false;
    });

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
    UserMode userMode = UserMode.friends;

    if (widget.enterContext == EnterContextUsersList.participantsModify) {
      userMode = UserMode.competitors;
    }
    await showSearch<Map<String, Set<String>?>>(
      context: context,
      delegate: UserSearcher(userMode: userMode),
    );
    updateList();
  }

  void showUserProfile(String uid) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'userMode': UserMode.friends, 'uid': uid},
    );
    updateList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 120),
      floatingActionButton: Visibility(
        visible:
            widget.enterContext == EnterContextUsersList.participantsModify ||
            widget.enterContext == EnterContextUsersList.friendsModify,
        child: FloatingActionButton(
          onPressed: onPressedAddUsers,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_add_alt_1, color: AppColors.white),
        ),
      ),
      appBar: AppBar(
        title: Text(
          pageTitle,
        ),
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
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () => showUserProfile(user.uid),
                      child: UserProfileTile(
                        key: ValueKey(user.uid),
                        user: user,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
