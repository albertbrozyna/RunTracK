import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/widgets/activity_block.dart';

import '../../../common/utils/app_data.dart';
import '../../../models/activity.dart';
import '../../../models/user.dart';
import '../../auth/start/pages/start_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "My"),
            Tab(text: "Friends"),
            Tab(text: "All"),
          ],
        ),
      ),
      body: TabBarView(
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
                      title: activity.title ?? "Untitled",
                      description: activity.description ?? "",
                      elapsedTime: activity.elapsedTime ?? Duration.zero,
                      activityDate: activity.startTime ?? DateTime.now(),
                      activityType: activity.activityType ?? "",
                      totalDistance: activity.totalDistance ?? 0,
                      photos: activity.photos ?? [],
                      trackedPath: activity.trackedPath ?? [],
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
    );
  }
}
