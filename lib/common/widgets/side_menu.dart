import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';

import '../../features/auth/register/pages/register_page.dart';

class SideMenu extends StatelessWidget{

  void onLogOutPressed(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user
      // We will automatically move to the signup page because of the stream that will trigger in main
    } catch (e) {
      // Handle error
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return
    Drawer(
     child: ListView(
       children: [
         ListTile(
           leading: Icon(Icons.login_outlined),
           title: Text("Log out"),
           onTap: () => onLogOutPressed(context),

         ),
         ListTile(
           leading: Icon(Icons.settings),
           title: Text("Settings"),
         )
       ],
     ),
    );
  }
  
}