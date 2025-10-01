import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/services/userService.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProfilePageState();
  }
}

class _ProfilePageState extends State<ProfilePage> {
  bool edit = false;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              decoration: BoxDecoration(),
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 23,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      !edit ? Icons.edit : Icons.check,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        edit = !edit;
                      });
                    },
                  ),

                  // Text(
                  //   !edit ? "Edit" : "Save",
                  //   style: TextStyle(color: Colors.white),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-first.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // My profile
                // Edit my info button

                // Profile photo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/DefaultProfilePhoto.png",
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.width / 2,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Name and last name
                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Column(
                      children: [
                        TextField(
                          controller:
                          "${AppData.currentUser?.firstName} ${AppData.currentUser?.lastName}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        Text("Email: ${AppData.currentUser?.email}")
                      ],
                    ),
                  ),
                ),
                // My email
                Container(
                  width: double.infinity,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24, width: 1),
                      ),
                    ),
                  ),

                  // Run Stats
                  // Container(
                  //   child: ,
                  // )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
