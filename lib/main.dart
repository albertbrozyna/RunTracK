
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/config/firebase_options.dart';
import 'app/navigation/app_router.dart';
import 'app/theme/app_theme.dart';

import 'features/auth/presentation/pages/start_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/track/data/services/track_foreground_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    // Block rotation
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ForegroundTrackService.instance.init();

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
      debugShowCheckedModeBanner: false,
    );
  }
}
