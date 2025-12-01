import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:run_track/core/utils/extensions.dart';
import 'package:run_track/core/utils/utils.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../core/constants/firestore_collections.dart';
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

  //Method to check password complexity
  bool checkPasswordComplexity(String password) {
    //Minimum 8 characters
    if (password.length < 7) return false;
    // At least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    // At least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    // At least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    // At least one special character
    if (!password.contains(RegExp(r'[!@#\$&*~%^]'))) return false;

    return true;
  }

  String? validateFields(String fieldName, String? value, {TextEditingController? passwordController}) {
    switch (fieldName) {
      case 'firstName':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your first name';
        }
        if (value.length < 2) {
          return 'First name must be at least 2 characters long';
        }
        break;
      case 'lastName':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your last name';
        }
        break;
      case 'email':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address';
        }
        if (!isEmailValid(value.trim())) {
          return 'Invalid email format';
        }
        break;
      case 'password':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a password';
        }
        if (!checkPasswordComplexity(value.trim())) {
          return 'Password must have at least 8 chars, one uppercase, lowercase, digit, and special character';
        }
        break;
      case 'repeatPassword':
        if (value == null || value.trim().isEmpty) {
          return 'Please repeat your password';
        }
        if (value.trim() != passwordController?.text.trim()) {
          return 'Passwords do not match';
        }
        break;
      case 'gender':
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        break;
      case 'dateOfBirth':
        if (value == null || value.trim().isEmpty) {
          return 'Please select your date of birth';
        }

        DateTime? date = DateTime.tryParse(value.trim());
        if (date == null) {
          return 'Invalid date format';
        }
        break;
      case 'weight':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your weight';
        }
        final number = double.tryParse(value.trim());

        if(number == null){
          return "Enter correct number";
        }

        if ( number <= 0) {
          return 'Weight must be greater than 0';
        }
        return null;
      case 'height':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your height';
        }
        final number = int.tryParse(value.trim());
        if(number == null){
          return "Height must be valid integer number";
        }

        if ( number <= 0) {
          return 'Height must be valid and greater than 0';
        }
        return null;
      default:
        return null;
    }
    return null;
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email);
  }

}
