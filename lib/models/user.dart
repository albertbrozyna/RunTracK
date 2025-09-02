import 'package:run_track/features/activities/pages/user_activities.dart';

class User {
  String firstName;
  String lastName;
  List<Activities>activities;
  List<String>friendsUids;
  String? email;

  User({
    required this.firstName,
    required this.lastName,
    required this.activities,
    required this.friendsUids,
    this.email
});

}