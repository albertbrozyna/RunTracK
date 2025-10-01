import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/widgets/activity_block.dart';
import 'package:run_track/theme/colors.dart';

import '../../../common/utils/app_data.dart';
import '../../../models/activity.dart';
import '../../../models/user.dart';

class Activities extends StatefulWidget {
  _ActivitiesState createState() => _ActivitiesState();
}

class _ActivitiesState extends State<Activities>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User>? friendsActivities;
  User? currentUser = AppData.currentUser;

  void fetchMyTrainings() {}

  void fetchMyFriendsTraining() {}

  void fetchActivitiesFromNeighborhood() {}

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withAlpha(100),
            labelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              backgroundColor: AppColors.primary,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            backgroundColor: AppColors.primary,
            ),
            tabs: [
              Tab(text: "My",),
              Tab(text: "Friends"),
              Tab(text: "All"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Container(
                  child: FutureBuilder<List<Activity>?>(
                    future: AppUtils.fetchUserActivities(currentUser!.uid, 10),
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

                Container(),
                Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
