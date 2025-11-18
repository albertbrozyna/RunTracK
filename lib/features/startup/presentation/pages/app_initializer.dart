import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/core/services/user_service.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';

import '../../../../core/utils/utils.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _navigateToStartPage();
      return;
    }

    try {
      if (AppData.instance.currentUser == null) {
        AppData.instance.currentUser = await UserService.fetchUser(firebaseUser.uid);

        if (!mounted) return;

        if (AppData.instance.currentUser == null) {
          AppUtils.showMessage(context, "User not found");
          _navigateToStartPage();
          return;
        }

        if (AppData.instance.currentUser!.currentCompetition.isNotEmpty) {
          AppData.instance.currentCompetition = await CompetitionService.fetchCompetition(
            AppData.instance.currentUser!.currentCompetition,
          );
          if (!mounted) return;

          if (AppData.instance.currentCompetition == null) {
            AppUtils.showMessage(context, "Competition not found");
            AppData.instance.currentUser?.currentCompetition = "";
            return;
          }
        }
      }

      _navigateToHome();
    } catch (e) {
      AuthService.instance.signOutUser();
      _navigateToStartPage();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _navigateToStartPage() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.start);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageContainer(
        darken: false,
        assetPath: AppImages.appBg4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  "RunTracK",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2))],
                  ),
                ),
              ),

              Image.asset(AppImages.runtrackAppIcon, width: 300),

              // Text under the logo
              const Text(
                'Track your runs, improve your fitness!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // change if needed
                  shadows: [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2))],
                ),
              ),
              AppLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
