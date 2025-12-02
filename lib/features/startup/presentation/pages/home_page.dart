import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/core/enums/user_mode.dart';
import 'package:run_track/core/models/activity.dart';
import 'package:run_track/core/utils/permission_utils.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/navigation_bar.dart';
import 'package:run_track/core/widgets/top_bar.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/competitions/presentation/pages/competition_page.dart';
import 'package:run_track/features/profile/presentation/pages/profile_page.dart';
import 'package:run_track/features/track/data/models/storage.dart';
import 'package:run_track/features/track/presentation/pages/activity_summary.dart';
import 'package:run_track/features/track/presentation/pages/track_screen.dart';
import 'package:run_track/features/track/data/models/track_state.dart';
import 'package:run_track/core/enums/tracking_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _askLocation() async {
    try {
      await PermissionUtils.determinePosition();
    } catch (e) {
      if (mounted) {
        AppUtils.showMessage(context, e.toString());
      }
    }
  }

  void _navigateToSummary(Activity? activity) {
    if (activity == null) return;
    activity.activityType = AppData.instance.currentUserCompetition?.activityType ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          firstName: AppData.instance.currentUser?.firstName ?? '',
          lastName: AppData.instance.currentUser?.lastName ?? '',
          activityData: activity,
          editMode: false,
          readonly: false,
          currentUserCompetition: AppData.instance.currentUserCompetition,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    if (await ActivityStorage.checkIfActivityExists()){
      Activity? activity = await ActivityStorage.loadActivity();
      _navigateToSummary(activity);
    }
    _askLocation();
  }

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

  Widget _getFreshPage(int index) {
    switch (index) {
      case 1:
        return const ActivitiesPage();
      case 2:
        return const CompetitionsPage();
      case 3:
        return ProfilePage(
          userMode: UserMode.friends,
          uid: FirebaseAuth.instance.currentUser?.uid ?? "",
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TrackState.trackStateInstance,
      builder: (context, child) {
        final trackState = TrackState.trackStateInstance;
        final bool isTrackingActive =
            trackState.trackingState == TrackingState.running ||
            trackState.trackingState == TrackingState.paused;
        final bool hasCompetition = trackState.currentUserCompetition.isNotEmpty;
        final bool shouldHideBars = isTrackingActive && hasCompetition;

        return Scaffold(
          appBar: TopBar(title: currentPageName(_selectedIndex), shouldHideButtons: shouldHideBars,selectedIndex: _selectedIndex,),
          body: Stack(
            children: [
              Offstage(offstage: _selectedIndex != 0, child: const TrackScreen()),

              if (_selectedIndex != 0) _getFreshPage(_selectedIndex),
            ],
          ),
          bottomNavigationBar: shouldHideBars
              ? null
              : BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
        );
      },
    );
  }
}
