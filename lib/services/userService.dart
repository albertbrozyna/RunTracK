

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/common/utils/app_data.dart';

class UserService{

  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.currentUser != null &&
        AppData.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

  static void signOutUser(){
    FirebaseAuth.instance.signOut();
    AppData.currentUser = null;
  }

}