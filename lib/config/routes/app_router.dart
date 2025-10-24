import 'package:flutter/material.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';
import 'package:run_track/features/home/home_page.dart';


import '../../features/track/pages/activity_summary.dart';
import '../../models/activity.dart';
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