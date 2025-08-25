// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'RunTracK';

  @override
  String get startPageWelcomeMessage => 'Track your runs, improve your fitness!';

  @override
  String get startPageLogin => 'Login';

  @override
  String get startPageRegister => 'No account? Join our community';

  @override
  String get trackScreenStartTraining => 'Start Training';
}
