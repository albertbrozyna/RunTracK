import 'package:flutter/foundation.dart';
import 'package:run_track/models/competition.dart';

import '../../models/user.dart';

class AppData{
  AppData._privateConstructor();
  static final AppData _instance = AppData._privateConstructor();
  static AppData get instance => _instance;

  User? currentUser;
  bool googleLogin = false;
  bool images = false; // Handling images
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  // Saved locally
  String? lastActivityString;

  Competition? currentCompetition;
}