import 'package:flutter/foundation.dart';

import '../../core/models/competition.dart';
import '../../core/models/user.dart';

class AppData{
  AppData._privateConstructor();
  static final AppData _instance = AppData._privateConstructor();
  static AppData get instance => _instance;

  User? currentUser;
  Competition? currentCompetition;
  Competition? currentUserCompetition;


  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  // Saved locally
  String? lastActivityString;

}