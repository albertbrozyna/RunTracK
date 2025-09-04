import 'package:run_track/features/activities/pages/user_activities.dart';

import 'activity.dart';

class User {
  String uid;
  String firstName;
  String lastName;
  List<Activity>activities;
  List<String>?activityNames;
  List<String>friendsUids;
  String? email;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.activities,
    required this.friendsUids,
    this.activityNames,
    this.email
});

}