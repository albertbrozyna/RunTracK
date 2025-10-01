import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/models/user.dart' as model;

class UserService {
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.currentUser != null &&
        AppData.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

  static void signOutUser() {
    FirebaseAuth.instance.signOut();
    AppData.currentUser = null;
  }

  /// Method used to calculate age of User
  static int calculateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 0;
    }
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  static model.User cloneUserData(model.User sourceUser) {
    return model.User(
      uid: sourceUser.uid,
      firstName: sourceUser.firstName,
      lastName: sourceUser.lastName,
      activities: sourceUser.activities != null
          ? sourceUser.activities!.map((a) => a.clone()).toList()
          : null,
      activityNames: sourceUser.activityNames != null
          ? List.from(sourceUser.activityNames!)
          : null,
      friendsUids: sourceUser.friendsUids != null
          ? List.from(sourceUser.friendsUids!)
          : null,
      email: sourceUser.email,
      profilePhotoUrl: sourceUser.profilePhotoUrl,
      dateOfBirth: sourceUser.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(
              sourceUser.dateOfBirth!.millisecondsSinceEpoch,
            )
          : null,
      defaultLocation: LatLng(
        sourceUser.userDefaultLocation.latitude,
        sourceUser.userDefaultLocation.longitude,
      ),
    );
  }

  static Future<bool> deleteUserFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is currently logged in.");
        return false;
      }
      final uid = user.uid;
      // Delete a collection from a firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

      print("User deleted successfully.");
      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  // To think
  // model.User? getUserData({required String uid,bool name = false, bool Activity = false, bool Friends = false,bool profilePhoto = false}){
  //   if(name){
  //
  //   })
  //
  // }
}
