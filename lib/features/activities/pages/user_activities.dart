import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';

import '../../../common/utils/app_data.dart';
import '../../../models/activity.dart';
import '../../../models/user.dart';

class Activities extends StatefulWidget {
  _ActivitiesState createState() => _ActivitiesState();
}

class _ActivitiesState extends State<Activities>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User>?friendsActivities;

  void fetchMyTrainings(){

  }

  void fetchMyFriendsTraining(){

  }

  void fetchActivitiesFromNeighborhood(){

  }

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activities"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "My"),
            Tab(text: "Friends"),
            Tab(text: "All"),
          ],
        ),
      ),
      body:TabBarView(
          controller: _tabController,
          children: [
        Container(
          child:
          FutureBuilder<List<Activity>?>(
          future: AppUtils.fetchUserActivities(, 10),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
          }
      )


        ),
        Container(),
        Container(),
      ]),
    );
  }
}
