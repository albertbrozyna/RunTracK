import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/widgets/activity_block.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';

import '../../../common/utils/app_data.dart';
import '../../../models/activity.dart';
import '../../../models/user.dart';

class ActivitiesPage extends StatefulWidget {
  _ActivitiesState createState() => _ActivitiesState();
}

class _ActivitiesState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User>? friendsActivities;
  User? currentUser = AppData.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initialize();
  }

  Future<void> initialize()  async{
    if (!UserService.isUserLoggedIn()) {
      await UserService.signOutUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background-start.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.25),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.primary),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withAlpha(100),
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                backgroundColor: AppColors.primary,
              ),
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
                  child: FutureBuilder<List<Activity>?>(
                    future: ActivityService.fetchLatestUserActivities(
                      currentUser!.uid,
                      10,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No activities found"));
                      }

                      final activities = snapshot.data!;

                      return ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return ActivityBlock(
                            firstName: currentUser!.firstName,
                            lastName: currentUser!.lastName,
                            activity: activity,
                          );
                        },
                      );
                    },
                  ),
                ),

                Container(
                  child: FutureBuilder<List<Activity>?>(
                    future: ActivityService.fetchLastFriendsActivities(
                      currentUser!.friendsUids!,
                      10,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No activities found"));
                      }

                      final activities = snapshot.data!;

                      return ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return ActivityBlock(
                            firstName: currentUser!.firstName,
                            lastName: currentUser!.lastName,
                            activity: activity,
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  child: FutureBuilder<List<Activity>?>(
                    future: ActivityService.fetchLatestActivities(10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No activities found"));
                      }

                      final activities = snapshot.data!;

                      return ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return ActivityBlock(
                            firstName: currentUser!.firstName,
                            lastName: currentUser!.lastName,
                            activity: activity,
                          );
                        },
                      );
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
