import '../../models/user.dart';

class AppData{
  static User? currentUser;
  static bool blockedLoginState = false;
  static bool images = false; // Handling images

  String? lastActivityString;


}