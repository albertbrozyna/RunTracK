import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/features/auth/presentation/pages/forget_password_page.dart';
import 'package:run_track/features/competitions/data/models/competition_result.dart';
import 'package:run_track/features/competitions/presentation/pages/competition_results_page.dart';
import 'package:run_track/features/settings/presentation/pages/change_password.dart';
import 'package:run_track/features/settings/presentation/pages/location_tracking_settings_page.dart';
import 'package:run_track/features/settings/presentation/pages/your_personal_info.dart';
import 'package:run_track/features/startup/presentation/pages/app_initializer.dart';
import 'package:run_track/features/startup/presentation/pages/home_page.dart';
import 'package:run_track/features/track/presentation/pages/tracked_path_map.dart';

import '../../core/enums/competition_role.dart';
import '../../core/enums/enter_context.dart';
import '../../core/enums/mode.dart';
import '../../core/enums/user_mode.dart';
import '../../core/models/activity.dart';
import '../../features/competitions/data/models/competition.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../core/pages/users_list.dart';
import '../../features/activities/pages/user_activities.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/start_page.dart';
import '../../features/competitions/presentation/pages/competition_det.dart';
import '../../features/competitions/presentation/pages/competition_page.dart';
import '../../features/competitions/presentation/pages/meeting_place_map.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/track/presentation/pages/activity_choose.dart';
import '../../features/track/presentation/pages/activity_summary.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.start:
        return MaterialPageRoute(builder: (_) => const StartPage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.competitionResults:
        final args = settings.arguments as Map<String, dynamic>?;
        final CompetitionResult? competitionResult =
            args?['competitionResult'] as CompetitionResult?;
        final String competitionId = args?['competitionId'] as String;
        return MaterialPageRoute(
          builder: (_) =>
              CompetitionResultsPage(result: competitionResult, competitionId: competitionId),
        );
      case AppRoutes.trackedPathMap:
        final args = settings.arguments as Map<String, dynamic>?;
        final List<LatLng> trackedPath = List<LatLng>.from(args?['trackedPath'] ?? []);

        return MaterialPageRoute(builder: (_) => TrackedPathMap(trackedPath: trackedPath));
      case AppRoutes.appInitializer:
        return MaterialPageRoute(builder: (_) => AppInitializer());
      case AppRoutes.forgetPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case AppRoutes.activitySummary:
        final args = settings.arguments as Map<String, dynamic>?;
        final Activity? activity = args?['activity'] as Activity?;
        final String firstName = args?['firstName'] ?? '';
        final String lastName = args?['lastName'] ?? '';
        final bool readOnly = args?['readOnly'] ?? true;
        final bool editMode = args?['editMode'] ?? false;

        if (activity == null) {
          return MaterialPageRoute(
            builder: (_) =>
                Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
          );
        }

        return MaterialPageRoute(
          builder: (_) => ActivitySummary(
            firstName: firstName,
            lastName: lastName,
            readonly: readOnly,
            editMode: editMode,
            activityData: activity,
          ),
        );

      case AppRoutes.activityChoose:
        final args = settings.arguments as Map<String, dynamic>?;
        final currentActivity = args?[' currentActivity'] ?? '';

        return MaterialPageRoute(builder: (_) => ActivityChoose(currentActivity: currentActivity));
      case AppRoutes.activities:
        return MaterialPageRoute(builder: (_) => const ActivitiesPage());

      case AppRoutes.competitions:
        return MaterialPageRoute(builder: (_) => const CompetitionsPage());
      case AppRoutes.competitionDetails:
        final args = settings.arguments as Map<String, dynamic>?;

        final enterContext = args?['enterContext'] as CompetitionContext;
        final competitionData = args?['competitionData'] as Competition?;
        final initTab = args?['initTab'] as int;

        return MaterialPageRoute(
          builder: (_) => CompetitionDetailsPage(
            enterContext: enterContext,
            competitionData: competitionData,
            initTab: initTab,
          ),
        );

      case AppRoutes.profile:
        final args = settings.arguments as Map<String, dynamic>?;
        final uid = args?['uid'] ?? '';
        final UserMode userMode = args?['userMode'] ?? UserMode.friends;

        return MaterialPageRoute(
          builder: (_) => ProfilePage(userMode: userMode, uid: uid),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case AppRoutes.usersList:
        final args = settings.arguments as Map<String, dynamic>?;
        final users = (args?['users'] as Set?)?.cast<String>() ?? <String>{};
        final enterContext = args?['enterContext'] as EnterContextUsersList;
        return MaterialPageRoute(
          builder: (_) => UsersList(users: users.toList(), enterContext: enterContext),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsPage());
      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
      case AppRoutes.yourPersonalInfo:
        return MaterialPageRoute(builder: (_) => const YourPersonalInfoPage());
      case AppRoutes.locationTrackingSettings:
        return MaterialPageRoute(builder: (_) => const LocationTrackingSettingsPage());
      case AppRoutes.meetingPlaceMap:
        final args = settings.arguments as Map<String, dynamic>?;
        final latLng = args?['latLng'] as LatLng?;
        final mode = args?['mode'] as Mode;
        return MaterialPageRoute(
          builder: (_) => MeetingPlaceMap(mode: mode, latLng: latLng),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
        );
    }
  }
}
