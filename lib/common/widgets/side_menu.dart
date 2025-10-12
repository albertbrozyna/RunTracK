import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/common/utils/app_data.dart';

import '../../features/profile/pages/profile_page.dart';
import '../../features/profile/pages/settings_page.dart';

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
      MaterialPageRoute(
        builder: (context) => ProfilePage(uid: AppData.currentUser?.uid),
      ),
    );
  }

  void onTapSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
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
                width: 50,
                height: 50,
              ),
            ),
            onTap: () => onTapMyProfile(context),
            title: Text(
              "${AppData.currentUser?.firstName} ${AppData.currentUser?.lastName}",
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () => onTapSettings(context),
          ),
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
