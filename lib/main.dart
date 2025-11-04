import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/permission_utils.dart';
import 'package:run_track/config/routes/app_router.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';
import 'package:run_track/features/auth/start/widgets/additional_info_form.dart';
import 'package:run_track/features/home/home_page.dart';
import 'package:run_track/features/track/pages/activity_summary.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/features/track/services/track_foreground_service.dart';
import 'package:run_track/theme/app_theme.dart';

import 'common/enums/tracking_state.dart';
import 'config/firebase_options.dart';
import 'features/track/models/track_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([ // Block rotation
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ForegroundTrackService.instance.init();


  AppData.trackState = TrackState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run TracK',
      theme: AppTheme.lightTheme,


      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'), // English
        Locale('pl'), // Polish (example)
      ],
      home: FirebaseAuth.instance.currentUser != null ? HomePage() : StartPage(),
      // home: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder: (context,snapshot) {
      //   if(AppData.blockedLoginState = false){
      //
      //   }
      //   // If we wait we showing a progress indicator
      //   if(snapshot.connectionState == ConnectionState.waiting){
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //   }
      //
      //   if(AppData.blockedLoginState){   // Show a windows to get
      //     return AdditionalInfo();
      //   }
      //
      //   // If we are logged in
      //   if(snapshot.data != null){  // Data is user?
      //       return HomePage();
      //   }
      //
      //   return StartPage();
      // }),
      debugShowCheckedModeBanner: false,
    );
  }
}

