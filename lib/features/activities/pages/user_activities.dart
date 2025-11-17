import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../app/config/app_data.dart';
import '../../../app/config/app_images.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/user.dart' as model;
import '../../../core/services/activity_service.dart';
import '../../../core/widgets/no_items_msg.dart';
import '../../../core/widgets/page_container.dart';
import '../widgets/activity_block.dart';



class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User>? friendsActivities;
  model.User? currentUser = AppData.instance.currentUser;

  final List<Activity> _myActivities = [];
  final List<Activity> _friendsActivities = [];
  final List<Activity> _allActivities = [];

  final ScrollController _scrollControllerMy = ScrollController();
  final ScrollController _scrollControllerFriends = ScrollController();
  final ScrollController _scrollControllerAll = ScrollController();

  // Loading state for every page
  bool _isLoadingMy = false;
  bool _isLoadingFriends = false;
  bool _isLoadingAll = false;

  // If there are more pages
  bool _hasMoreMy = true;
  bool _hasMoreFriends = true;
  bool _hasMoreAll = true;

  DocumentSnapshot? _lastPageMyActivities;
  DocumentSnapshot? _lastPageFriendsActivities;
  DocumentSnapshot? _lastPageAllActivities;

  final int _limit = 10; // Activities per page

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerMy.dispose();
    _scrollControllerFriends.dispose();
    _scrollControllerAll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    _tabController = TabController(length: 3, vsync: this);
  }

  void initialize() {
    AuthService.instance.checkAppUseState(context);

    // Load activities on start
    _loadMyActivities();
    _loadFriendsActivities();
    _loadAllActivities();

    // Listeners for scroll controller to load more activities
    _scrollControllerMy.addListener(() {
      if (_scrollControllerMy.position.pixels >= _scrollControllerMy.position.maxScrollExtent - 200) {
        _loadMyActivities();
      }
    });

    _scrollControllerFriends.addListener(() {
      if (_scrollControllerFriends.position.pixels >= _scrollControllerFriends.position.maxScrollExtent - 200) {
        _loadFriendsActivities();
      }
    });

    _scrollControllerAll.addListener(() {
      if (_scrollControllerAll.position.pixels >= _scrollControllerAll.position.maxScrollExtent - 200) {
        _loadAllActivities();
      }
    });
  }

  Future<void> initializeAsync() async {}

  /// Load my activities
  Future<void> _loadMyActivities() async {
    if (_isLoadingMy || !_hasMoreMy) {
      return;
    }
    setState(() {
      _isLoadingMy = true;
    });

    final activitiesFetchResult = await ActivityService.fetchMyLatestActivitiesPage(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      _limit,
      _lastPageMyActivities,
    );

    if(!mounted) return;
    setState(() {
      _myActivities.addAll(activitiesFetchResult.activities);
      _lastPageMyActivities = activitiesFetchResult.lastDocument;
      _isLoadingMy = false;
      if (activitiesFetchResult.activities.length < _limit) {
        _hasMoreMy = false;
      }
    });
  }

  Future<void> _loadFriendsActivities() async {
    if (_isLoadingFriends || !_hasMoreFriends) {
      return;
    }
    setState(() {
      _isLoadingFriends = true;
    });

    final activitiesFetchResult = await ActivityService.fetchLastFriendsActivitiesPage(
      _limit,
      _lastPageFriendsActivities,
      currentUser?.friends ?? {},
    );
    if(!mounted) return;

    setState(() {
      if (activitiesFetchResult.activities.isEmpty) {
        _hasMoreFriends = false;
      } else {
        _friendsActivities.addAll(activitiesFetchResult.activities);
        _lastPageFriendsActivities = activitiesFetchResult.lastDocument;
        if (activitiesFetchResult.activities.length < _limit) {
          _hasMoreFriends = false;
        }
      }
      _isLoadingFriends = false;
    });
  }


  /// Load last competitions from all users
  Future<void> _loadAllActivities() async {
    if (_isLoadingAll == true || _hasMoreAll == false) {
      return;
    }

    setState(() {
      _isLoadingAll = true;
    });

    final activitiesFetchResult = await ActivityService.fetchLatestActivitiesPage(_limit, _lastPageAllActivities);
    if(!mounted) return;

    setState(() {
      _allActivities.addAll(activitiesFetchResult.activities);
      _lastPageAllActivities = activitiesFetchResult.lastDocument;

      _isLoadingAll = false;

      if (activitiesFetchResult.lastDocument == null) {
        _hasMoreAll = false;
      }
    });

    if (activitiesFetchResult.activities.isEmpty && _hasMoreAll == true && mounted) {
      Future.microtask(() => _loadAllActivities());
    }
  }


  @override
  Widget build(BuildContext context) {
    return PageContainer(
      assetPath: AppImages.appBg4,
      padding: 0,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.primary),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withAlpha(100),
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: Colors.white,
              unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, backgroundColor: AppColors.primary),
              tabs: [
                Tab(text: "My"),
                Tab(text: "Friends"),
                Tab(text: "All"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 10),
                  child: _myActivities.isEmpty ? NoItemsMsg(textMessage: "No activities found") : ListView.builder(
                  controller: _scrollControllerMy,
                    itemCount: _myActivities.length + (_hasMoreMy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _myActivities.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final activity = _myActivities[index];
                      return ActivityBlock(
                        key: ValueKey(activity.activityId),
                        firstName: currentUser!.firstName,
                        lastName: currentUser!.lastName,
                        activity: activity,
                      );
                    },
                  ),
                ),
                // Friends
                Container(
                  padding: EdgeInsets.only(top: 10),
                  child: _friendsActivities.isEmpty ? NoItemsMsg(textMessage: "No activities found") : ListView.builder(
                    controller: _scrollControllerFriends,
                    itemCount: _friendsActivities.length + (_hasMoreFriends ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _friendsActivities.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final activity = _friendsActivities[index];
                      return ActivityBlock(key: ValueKey(activity.activityId), firstName: "", lastName: "", activity: activity);
                    },
                  ),
                ),
                // All last activities
                Container(
                  padding: EdgeInsets.only(top: 10),
                  child: _allActivities.isEmpty ? NoItemsMsg(textMessage: "No activities found") : ListView.builder(
                    controller: _scrollControllerAll,
                    itemCount: _allActivities.length + (_hasMoreAll ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _allActivities.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final activity = _allActivities[index];
                      return ActivityBlock(key: ValueKey(activity.activityId), firstName: "", lastName: "", activity: activity);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
