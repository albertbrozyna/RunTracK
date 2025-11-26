import 'package:flutter/foundation.dart';

import '../../features/competitions/data/models/competition.dart';
import '../../core/models/user.dart';

class AppData{
  AppData._pvConstructor();
  static final AppData _instance = AppData._pvConstructor();
  static AppData get instance => _instance;

  User? currentUser;
  Competition? currentCompetition;
  Competition? currentUserCompetition;
  String? lastActivityString;
}