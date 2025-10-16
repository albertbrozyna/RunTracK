import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/models/user.dart';

import '../../../services/user_service.dart';
import '../../../theme/colors.dart';

class ParticipantsList extends StatefulWidget{
  final List<String> usersUids;

  const ParticipantsList({super.key,required this.usersUids});

  @override
  State<StatefulWidget> createState() {
    return _ParticipantsListState();
  }
}

class _ParticipantsListState extends State<ParticipantsList>{
  final List<User> _users = [];

  DocumentSnapshot? lastDocument;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Friends per page
  bool _hasMore = true;
  bool _isLoading = false;
  late List<String> usersUids;
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
    usersUids = widget.usersUids;

  }

  /// Load my activities
  Future<void> _loadUsers() async {
    if (_isLoading == true || _hasMore == false) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final activities = await UserService.fetchUsers(
      uids: usersUids,
      lastDocument: lastDocument,
      limit: _limit,
    );

    setState(() {
      _users.addAll(activities);
      lastDocument = activities.isNotEmpty ? UserService.lastFetchedDocumentParticipants : null;
      _isLoading = false;
      if (activities.length < _limit) {
        _hasMore = false;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Participants",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
        ),
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