import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/competitions/pages/competition_page.dart';
import 'package:run_track/features/profile/pages/profile_page.dart';
import 'package:run_track/features/track/pages/track_screen.dart';
import 'package:run_track/services/user_service.dart';

import '../../common/widgets/navigation_bar.dart';
import '../../common/widgets/top_bar.dart';
import 'package:run_track/common/utils/permission_utils.dart';

import '../../services/competition_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> _pages;
  int _selectedIndex = 0;
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Ask user for location
  Future<void> _askLocation() async {
    try {
      await PermissionUtils.determinePosition();
    } catch (e) {
      if (mounted) {
        AppUtils.showMessage(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    isTrackingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadAppData() async {
    if (FirebaseAuth.instance.currentUser != null && AppData.instance.currentUser == null) {
      AppData.instance.currentUser = await UserService.fetchUser(FirebaseAuth.instance.currentUser!.uid);
    }
    if (AppData.instance.currentUser != null && AppData.instance.currentUser!.currentCompetition.isNotEmpty) {
      AppData.instance.currentCompetition = await CompetitionService.fetchCompetition(AppData.instance.currentUser!.currentCompetition);
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    _pages = [TrackScreen(), ActivitiesPage(), CompetitionsPage(), ProfilePage(uid:  FirebaseAuth.instance.currentUser?.uid,)];
  }

  Future<void> initializeAsync() async {
    AppData.instance.isLoading.value = true; // Start loading
    _loadAppData();
    AppData.instance.isLoading.value = false;

    _askLocation();
  }

  /// Get current page name
  String currentPageName(int index) {
    switch (index) {
      case 0:
        return "RunTracK";
      case 1:
        return "Activities";
      case 2:
        return "Competitions";
      case 3:
        return "My profile";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: currentPageName(_selectedIndex),),
      body: _pages[_selectedIndex],
      bottomNavigationBar: (_selectedIndex == 0)
          ? ValueListenableBuilder<bool>(
              valueListenable: isTrackingNotifier,
              builder: (context, isTracking, _) {
                return isTracking ? SizedBox.shrink() : BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped);
              },
            )
          : BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}
