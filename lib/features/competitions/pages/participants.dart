import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  final ScrollController _scrollController = ScrollController();
  final int _limit = 20; // Friends per page
  bool _hasMore = true;
  bool _isLoading = false;
  late List<String> usersUids;
  @override
  void initState() {
    super.initState();
    initialize();

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

    final activities = await ActivityService.fetchMyLatestActivitiesPage(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      _limit,
      _lastPageMyActivities,
    );

    setState(() {
      _myActivities.addAll(activities);
      _lastPageMyActivities = activities.isNotEmpty ? ActivityService.lastFetchedDocumentMyActivities : null;
      _isLoadingMy = false;
      if (activities.length < _limit) {
        _hasMoreMy = false;
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
      body: Container(


      ),
    )
  }

}