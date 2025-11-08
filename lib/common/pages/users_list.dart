import 'package:flutter/material.dart';
import 'package:run_track/common/enums/enter_context.dart';
import 'package:run_track/common/widgets/no_items_msg.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/config/routes/app_routes.dart';
import 'package:run_track/models/user.dart';

import '../../config/assets/app_images.dart';
import '../../features/track/widgets/fab_location.dart';
import '../widgets/searcher_users.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

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
  List<String> _usersUid = []; // List of participants
  List<String> _usersUid2 = []; // For participants context it is list of invited
  List<String> _usersUid3 = []; // For participants context it is list of invited
  bool visibleFabAdd = false;
  String? lastUid; // Last uid for pagination
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Users per page
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
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.start, (route) => false);
      return;
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        _loadUsers();
      }
    });

    // Set title and message depends on context
    if (widget.enterContext == EnterContextUsersList.participantsModify ||
        widget.enterContext == EnterContextUsersList.participantsReadOnly) {
      pageTitle = "Participants";
      noItemsMessage = "No participants found";
    } else if (widget.enterContext == EnterContextUsersList.friendsModify) {
      pageTitle = "Friends";
      noItemsMessage = "No friends found";
    }

    _usersUid = widget.usersUid.toList();
    _usersUid2 = widget.usersUid2.toList();
    _usersUid3 = widget.usersUid3.toList();

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
    if (widget.enterContext == EnterContextUsersList.participantsLookAndInvite) {
      enterContextSearcher = EnterContextSearcher.participants;
    }

    final result = await showSearch<Map<String, Set<String>?>>(
      context: context,
      delegate: UserSearcher(
        enterContext: enterContextSearcher,
        listUsers: _usersUid.toSet(),
        invitedUsers: _usersUid2.toSet(),
        receivedInvitations: _usersUid3.toSet(),
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
