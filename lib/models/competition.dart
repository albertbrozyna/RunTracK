

import 'package:firebase_auth/firebase_auth.dart';

class Competition{
  String? cid; // Competition id
  User organizer; // Event organizer
  String name;
  List<User>?participants;
  List<User>?invitedParticipants;
  String? visibility;
  List<User>?results;  // List of winners

  Competition({
    required this.name,
    required this.organizer
});
}