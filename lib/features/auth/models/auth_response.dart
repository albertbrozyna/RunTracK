import 'package:firebase_auth/firebase_auth.dart';

class AuthResponse {
  final UserCredential? userCredential;
  final String? message;

  AuthResponse({this.userCredential, this.message});
}
