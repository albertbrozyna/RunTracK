import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:run_track/core/services/user_service.dart';

import '../enums/SignInStatus.dart';
import '../models/sign_in_result.dart';
import '../models/user.dart' as model;


class GoogleService {
  GoogleService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with google
  static Future<SignInResult> signInWithGoogle() async {
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

  static void signOutFromGoogle(){
    _googleSignIn.signOut();
  }

}
