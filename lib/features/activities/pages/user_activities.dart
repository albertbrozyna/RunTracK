import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Activities extends StatefulWidget {
  _ActivitiesState createState() => _ActivitiesState();
}

class _ActivitiesState extends State<Activities>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<> myActivities = [];
  List<Activities> myActivities = [];

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
          tabs: [
            Tab(text: "My"),
            Tab(text: "Friends"),
            Tab(text: "All"),
          ],
        ),
      ),
      body:TabBarView(children: [
        Container(),
        Container(),
        Container(),
      ]),
    );
  }
}
