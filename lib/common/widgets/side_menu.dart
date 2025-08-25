import 'package:flutter/material.dart';


class SideMenu extends StatelessWidget{

  void onLogOutPressed(){

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