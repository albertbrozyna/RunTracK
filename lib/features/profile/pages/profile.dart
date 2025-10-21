import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/widgets/activity_block.dart';
import 'package:run_track/features/profile/pages/profile_page.dart';
import 'package:run_track/features/profile/pages/settings_page.dart';
import 'package:run_track/features/profile/pages/stats.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/competition_service.dart';
import 'package:run_track/theme/colors.dart';

import '../../../../common/utils/app_data.dart';
import '../../../../models/activity.dart';
import '../../../../models/user.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfile();
}

class _MyProfile extends State<MyProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/appBg4.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken),
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
                unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, backgroundColor: AppColors.primary),
                tabs: [
                  Tab(text: "My profile"),
                  Tab(text: "My stats"),
                  Tab(text: "Settings"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ProfilePage(uid: FirebaseAuth.instance.currentUser?.uid),
                  Stats(),
                  SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
