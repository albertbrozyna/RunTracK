import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../home/home_page.dart';
import '../pages/start_page.dart';
import 'home_page.dart';
import 'firebase_auth_start_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return HomePage();
        }

        return const StartPage();
      },
    );
  }
}
