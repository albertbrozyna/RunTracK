import 'package:flutter/foundation.dart';
import 'package:run_track/features/track/models/track_state.dart';

import '../../models/user.dart';

class AppData{
  static User? currentUser;
  static bool googleLogin = false;
  static bool images = false; // Handling images
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);
  // Saved locally
  static String? lastActivityString;

  // When no internet activities which we need to add
  List<String>activities = [];
  static late  TrackState trackState;

}