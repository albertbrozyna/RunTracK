import 'package:flutter/material.dart';
import 'package:run_track/common/pages/notifications_page.dart';
import 'package:run_track/features/activities/pages/user_activities.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';
import 'package:run_track/features/competitions/pages/competition_page.dart';
import 'package:run_track/features/home/home_page.dart';
import 'package:run_track/features/profile/pages/profile_page.dart';
import 'package:run_track/features/settings/pages/settings_page.dart';


import '../../common/enums/enter_context.dart';
import '../../common/pages/users_list.dart';
import '../../features/track/pages/activity_choose.dart';
import '../../features/track/pages/activity_summary.dart';
import '../../models/activity.dart';
import '../../models/user.dart';
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
      case AppRoutes.activitySummary:
        final args = settings.arguments as Map<String, dynamic>?;
        final Activity? activity = args?['activity'] as Activity?;

        if(activity == null){
          return MaterialPageRoute(builder: (_) => Scaffold(
            // TODO ERROR PAGE
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),);
        }

        final firstName = args?['firstName'] ?? '';
        final lastName = args?['lastName'] ?? '';
        final readOnly = args?['readOnly'] ?? '';
        final editMode = args?['editMode'] ?? '';

        return MaterialPageRoute(builder: (_) => ActivitySummary(firstName: firstName, lastName: lastName, readonly: readOnly, editMode: editMode,activityData: activity,));

      case AppRoutes.activityChoose:
        final args = settings.arguments as Map<String, dynamic>?;
        final currentActivity = args?[' currentActivity'] ?? '';

        return MaterialPageRoute(builder: (_) => ActivityChoose(currentActivity: currentActivity));
      case AppRoutes.activities:
        return MaterialPageRoute(builder: (_) => const ActivitiesPage());

      case AppRoutes.competitions:
        return MaterialPageRoute(builder: (_) => const CompetitionsPage());
      case AppRoutes.profile:
        final args = settings.arguments as Map<String, dynamic>?;
        final uid = args?['uid'] ?? '';
        final passedUser = args?['passedUser'] as User?;
        final usersList = args?['usersList'] ?? [];
        final invitedUsers = args?['invitedUsers'] ?? [];
        final receivedInvites = args?['receivedInvites'] ?? [];

        return MaterialPageRoute(builder: (_) => ProfilePage(uid: uid,usersList: usersList,invitedUsers: invitedUsers,receivedInvites: receivedInvites));

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case AppRoutes.usersList:
        final args = settings.arguments as Map<String, dynamic>?;
        final usersUid = args?['usersUid'] ?? [];
        final usersUid2 = args?['usersUid2'] ?? [];
        final usersUid3 = args?['usersUid3'] ?? [];
        final enterContext = args?['enterContext']  as EnterContextUsersList;

        return MaterialPageRoute(builder: (_) => UsersList(usersUid: usersUid,usersUid2: usersUid2,usersUid3: usersUid3,enterContext: enterContext));
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}