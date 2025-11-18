import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/enums/user_mode.dart';
import 'package:run_track/core/utils/permission_utils.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/navigation_bar.dart';
import 'package:run_track/core/widgets/top_bar.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/competitions/presentation/pages/competition_page.dart';
import 'package:run_track/features/profile/presentation/pages/profile_page.dart';
import 'package:run_track/features/track/presentation/pages/track_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> _pages;
  int _selectedIndex = 0;

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
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    _pages = [
      TrackScreen(),
      ActivitiesPage(),
      CompetitionsPage(),
      ProfilePage(userMode: UserMode.friends, uid: FirebaseAuth.instance.currentUser?.uid ?? ""),
    ];
  }

  Future<void> initializeAsync() async {
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
      appBar: TopBar(title: currentPageName(_selectedIndex)),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}
