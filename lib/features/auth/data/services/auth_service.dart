import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:run_track/core/utils/extensions.dart';
import 'package:run_track/core/utils/utils.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../core/constants/firestore_names.dart';
import '../../../../core/enums/sign_in_status.dart';
import '../models/sign_in_result.dart';
import '../../../../core/models/user.dart' as model;
import '../../../../core/services/user_service.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService._();

  final firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static final AuthService instance = AuthService._();

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.instance.currentUser != null &&
        AppData.instance.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

  /// Sign out user
  Future<void> signOutUser() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    AppData.instance.currentUser = null;
  }

  void checkAppUseState(BuildContext context) {
    if (!isUserLoggedIn()) {
      signOutUser();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.start, (route) => false);
        }
      });
    }
  }


  Future<void> deleteDocumentsByQuery(Query query) async {
    const batchSize = 40;
    QuerySnapshot snapshot = await query.limit(batchSize).get();

    while (snapshot.docs.isNotEmpty) {
      final WriteBatch batch = firestore.batch();

      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot = await query.limit(batchSize).get();
    }
  }

  Future<AuthResponse> deleteUserAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return AuthResponse(message: "User is not logged in.");
      }

      final uid = user.uid;
      // Delete notifications
      final queryNotifications = firestore.collection(FirestoreCollections.notifications)
          .where('uid', isEqualTo: uid);
      await deleteDocumentsByQuery(queryNotifications);
      // Delete activities
      final queryActivities = firestore.collection(FirestoreCollections.activities)
          .where('uid', isEqualTo: uid);
      await deleteDocumentsByQuery(queryActivities);
      // Delete user profile
      await firestore.collection(FirestoreCollections.users).doc(uid).delete();

      await user.delete();
      await signOutUser();

      return AuthResponse(message: "Account deleted successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResponse(message: "You need to log in again to do this operation.");
      }
      return AuthResponse(message: "Firebase Auth error: ${e.message}");
    } catch (e) {
      return AuthResponse(message: "Account deleted, but error: $e");
    }
  }

  /// Create a user in firebase auth
  Future<AuthResponse> createUserInFirebaseAuth(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      return AuthResponse(message: "User created", userCredential: userCredential);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(message: "Auth error ${e.message}");
    } catch (e) {
      return AuthResponse(message: "Auth error $e");
    }
  }

  /// Create user account in firestore
  Future<String> createUserInFirestore(
    String uid,
    String firstname,
    String lastname,
    String email,
    String gender,
    DateTime dateOfBirth,
  ) async {
    await UserService.addUser(
      model.User(
        uid: uid,
        firstName: firstname.trim().toLowerCase().capitalize(),
        lastName: lastname.trim().toLowerCase().capitalize(),
        email: email.trim().toLowerCase(),
        gender: gender.trim().toLowerCase(),
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
        activityNames: AppUtils.getDefaultActivities(),
        friends: {},
      ),
    );

    return "User created";
  }



  /// Sign in with google
  Future<SignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return SignInResult(status: SignInStatus.failed);
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Check if user account exists, if not create one
      bool userExists = await UserService.checkIfUserAccountExists(
        userCredential.user!.uid,
      );

      if (!userExists) {
        // Split user display name
        final fullName = googleUser.displayName ?? "";
        final nameParts = fullName.split(" ");

        String firstName = "";
        String lastName = "";

        if (nameParts.isNotEmpty) {
          firstName = nameParts.first;
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
        }

        model.User newUser = model.User(
          uid: userCredential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: googleUser.email,
          gender: null,
        );

        return SignInResult(
          status: SignInStatus.userDoesNotExists,
          user: newUser,
        );
      }

      return SignInResult(status: SignInStatus.success);
    } on FirebaseAuthException catch (e) {
      return SignInResult(status: SignInStatus.failed, errorMessage: e.message);
    } catch (e) {
      return SignInResult(
        status: SignInStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

}
