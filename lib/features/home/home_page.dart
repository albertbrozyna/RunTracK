import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/enums/tracking_state.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/competitions/pages/competition_page.dart';
import 'package:run_track/features/profile/pages/profile.dart';
import 'package:run_track/features/track/pages/track_screen.dart';
import 'package:run_track/services/user_service.dart';

import '../../common/widgets/navigation_bar.dart';
import '../../common/widgets/side_menu.dart';
import '../../common/widgets/top_bar.dart';
import '../../theme/colors.dart';
import 'package:run_track/common/utils/permission_utils.dart';
import 'package:run_track/features/track/models/track_state.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // TODO To learn
  late List<Widget> _pages;
  int _selectedIndex = 0;
  TrackState? trackState;
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  void Dispose(){
    isTrackingNotifier.dispose();
    super.dispose();
  }
  Future<void> _loadCurrentUser() async {
    if (FirebaseAuth.instance.currentUser != null &&
        AppData.currentUser == null) {

      AppData.currentUser = await UserService.fetchUser(
        FirebaseAuth.instance.currentUser!.uid
      );
      setState(() {
      });
    }
  }

  @override
  void initState()  {
    super.initState();
    initialize();
    _pages = [TrackScreen(), ActivitiesPage(), CompetitionsPage(), MyProfile()];
    _loadCurrentUser();
    LocationService.determinePosition();
  }

  Future<void>initialize() async {
    AppData.isLoading.value = true; // Start loading
    TrackState? lastState = await TrackState.loadFromFile();
    AppData.trackState =  lastState ?? TrackState();

    // Set track state to paused i last state was running
    if(AppData.trackState.trackingState == TrackingState.running){
      AppData.trackState.trackingState = TrackingState.paused;
    }
    AppData.isLoading.value = false;

    // Add listener
    AppData.trackState.addListener(() {
      isTrackingNotifier.value = AppData.trackState.trackingState == TrackingState.running || AppData.trackState.trackingState == TrackingState.paused;
    });
  }

  String currentPageName(int index){
    switch(index){
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
      appBar: TopBar(
        backgroundColor: AppColors.secondary,
      title: currentPageName(_selectedIndex),

      ),
      body: _pages[_selectedIndex],

      bottomNavigationBar: (_selectedIndex == 0)
          ? ValueListenableBuilder<bool>(
        valueListenable: isTrackingNotifier,
        builder: (context, isTracking, _) {
          return isTracking
              ? SizedBox.shrink()
              : BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          );
        },
      )
          : BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
