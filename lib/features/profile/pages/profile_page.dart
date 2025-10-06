import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:run_track/models/user.dart' as model;
import 'dart:math';

class ProfilePage extends StatefulWidget {
  final String? uid;

  const ProfilePage({this.uid});

  @override
  State<StatefulWidget> createState() {
    return _ProfilePageState();
  }
}

class _ProfilePageState extends State<ProfilePage> {
  bool edit = false;
  bool changes = false;
  bool myProfile =
      false; // Variable that tells us if we are viewing our own profile or not
  model.User? user; // User which we are showing
  model.User? userBeforeChange;
  model.User? userAfterChange;
  List<String> randomFriends = [];
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.uid == null) {
      // TODO handle error
    }

    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
    }
    if (widget.uid == AppData.currentUser?.uid) {
      myProfile = true;
    }
    initFields();
    randomFriends.addAll(
      getRandomFriends(AppData.currentUser?.friendsUids ?? [], 6),
    );
  }

  void initData() {
    if (myProfile) {
      userBeforeChange = UserService.cloneUserData(AppData.currentUser!);
    }
  }

  // Pick a count random friends from user friends
  List<String> getRandomFriends(List<String> friends, int count) {
    if (friends.isEmpty) return [];

    final random = Random();
    final friendsCopy = List<String>.from(
      friends,
    ); // make a copy to avoid modifying original
    final result = <String>[];

    // Pick up to `count` random friends
    final pickCount = count <= friendsCopy.length ? count : friendsCopy.length;

    for (int i = 0; i < pickCount; i++) {
      final index = random.nextInt(friendsCopy.length);
      result.add(friendsCopy[index]);
      friendsCopy.removeAt(index); // avoid duplicates
    }

    return result;
  }
  /// Delete account action
  void deleteAccountButtonPressed(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete", textAlign: TextAlign.center),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
            textAlign: TextAlign.center,
          ),
          alignment: Alignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                  },
                  child: const Text("Cancel"),
                ),
                SizedBox(width: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    UserService.deleteUserFromFirestore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Account deleted")),
                    );
                    UserService.signOutUser();
                  },
                  child: const Text("Delete my account"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Logout button action
  void logoutButtonPressed(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout", textAlign: TextAlign.center),
          content: const Text(
            "Are you sure you want to log out?",
            textAlign: TextAlign.center,
          ),
          alignment: Alignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                  },
                  child: const Text("Cancel"),
                ),
                SizedBox(width: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop();
                    UserService.signOutUser();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logged out")),
                    );
                    UserService.signOutUser();
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ],
        );
      },
    );


  }



  /// Function invoked when edit is finished and changes are saved
  void onEditFinished() {}

  // Init fields
  void initFields() {
    //TODO uncomment
    // firstNameController.text = AppData.currentUser?.firstName ?? "";
    // lastNameController.text = AppData.currentUser?.lastName ?? "";
    firstNameController.text = "Albert";
    lastNameController.text = "Brożyna";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-first.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.30),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
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
                          changes = true;
                          if (edit) {
                            onEditFinished();
                          }
                          edit = !edit;
                        });
                      },
                    ),
                  ],
                ),

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
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Name
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  border: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                  enabledBorder: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                  focusedBorder: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                  hintText: !edit ? "" : "First name",
                                  label: Text(
                                    !edit ? "" : "First name",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  filled: edit ? true : false,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.4,
                                  ),
                                ),

                                textAlign: edit
                                    ? TextAlign.center
                                    : TextAlign.right,
                                controller: firstNameController,
                                readOnly: edit ? false : true,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            SizedBox(width: 13),
                            // Last name
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  border: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                  enabledBorder: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                  focusedBorder: !edit
                                      ? InputBorder.none
                                      : OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                  hintText: !edit ? "" : "Last name",
                                  label: Text(
                                    !edit ? "" : "First name",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  filled: edit ? true : false,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                controller: lastNameController,
                                readOnly: edit ? false : true,
                                textAlign: edit
                                    ? TextAlign.center
                                    : TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              textAlign: TextAlign.center,

                              "Email: ",
                              style: TextStyle(
                                color: Colors.white24,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              "${AppData.currentUser?.email}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Date of birth
                if (!edit && AppData.currentUser?.dateOfBirth != null)
                  Text(
                    "Age: ${UserService.calculateAge(AppData.currentUser?.dateOfBirth)}",
                  ),
                if (edit) // Date of birth
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    // Makes the field non-editable
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.4),
                      labelText: "Date of Birth",
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(width: 1, color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(width: 1, color: Colors.white),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        _dateController.text = formattedDate;
                      }
                    },
                  ),
                SizedBox(height: 10),
                // Friend list
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Friends: ${user?.friendsUids?.length ?? 0}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),

                      // TODO To test
                      // Pick up to 6 random friends
                      if ((user?.friendsUids?.isNotEmpty ?? false))
                        Row(
                          children: [
                            ...getRandomFriends(user!.friendsUids!, 3).map(
                              (friend) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  friend,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // TODO
                //Run Stats
                // Container(
                //   child: ,
                // )

                // Log out button
                SizedBox(height: 20),

                if(!edit)
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(AppColors.primary),
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: Colors.white24,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      onPressed: () => deleteAccountButtonPressed(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Log out",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.logout, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),


                // Delete profile button
                if (edit)
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        side: MaterialStateProperty.all(
                          BorderSide(
                            color: Colors.white24,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      onPressed: () => deleteAccountButtonPressed(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Delete my account",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
