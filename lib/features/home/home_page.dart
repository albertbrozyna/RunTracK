import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/tracking_state.dart';
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
import 'package:run_track/features/track/models/track_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> _pages;
  int _selectedIndex = 0;
  TrackState? trackState;
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  List<LatLng> track = [];
  LatLng? currentPosition;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Ask user for location
  Future<void> _askLocation() async {
    try {
      await LocationService.determinePosition();
    } catch (e) {
      if (mounted) {
        AppUtils.showMessage(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    isTrackingNotifier.dispose();
    FlutterForegroundTask.removeTaskDataCallback((data) {});

  super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (FirebaseAuth.instance.currentUser != null && AppData.currentUser == null) {
      AppData.currentUser = await UserService.fetchUser(FirebaseAuth.instance.currentUser!.uid);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
    _pages = [TrackScreen(), ActivitiesPage(), CompetitionsPage(), ProfilePage(uid:  FirebaseAuth.instance.currentUser?.uid,)];
    _loadCurrentUser();
  }

  void initialize(){

    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map && data.containsKey('lat') && data.containsKey('lng')) {
        LatLng pos = LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );

        setState(() {
          currentPosition = pos;
          track.add(pos);
        });

        print("📍 Otrzymano lokalizację: $pos");
      } else {
        print("⚠️ Otrzymano niepoprawne dane: $data");
      }
    });
  }


  Future<void> initializeAsync() async {
    AppData.isLoading.value = true; // Start loading
    TrackState? lastState = await TrackState.loadFromFile();

    // Set track state to paused i last state was running
    // if (AppData.trackState.trackingState == TrackingState.running) {
    //   AppData.trackState.trackingState = TrackingState.paused;
    // }
    AppData.isLoading.value = false;

    // Add listener
    // AppData.trackState.addListener(() {
    //   isTrackingNotifier.value =
    //       AppData.trackState.trackingState == TrackingState.running || AppData.trackState.trackingState == TrackingState.paused;
    // });
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
