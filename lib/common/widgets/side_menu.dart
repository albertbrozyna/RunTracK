import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/common/utils/app_data.dart';

import '../../features/sideMenu/profile_page.dart';

class SideMenu extends StatelessWidget {
  void onLogOutPressed(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user
      // We will automatically move to the signup page because of the stream that will trigger in main
    } catch (e) {
      // Handle error
      print('Error signing out: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out')));
    }
  }

  // on tap
  void onTapMyProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void onTapSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: ClipOval(
              child: Image.asset(
                "assets/DefaultProfilePhoto.png",
                width: 40,
                height: 40,
              ),
            ),
            title: Text(
              "${AppData.currentUser?.firstName} ${AppData.currentUser?.lastName}",
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            onTap: () => onTapMyProfile(context),
            title: Text("My profile"),
          ),
          ListTile(leading: Icon(Icons.settings), title: Text("Settings")),
          ListTile(
            leading: Icon(Icons.login_outlined),
            title: Text("Log out"),
            onTap: () => onLogOutPressed(context),
          ),
        ],
      ),
    );
  }
}
