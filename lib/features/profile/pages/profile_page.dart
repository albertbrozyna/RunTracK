import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/no_items_msg.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:run_track/models/user.dart' as model;
import 'dart:math';

import '../../../common/utils/utils.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;  // uid of the user which we need to show a profile
  final model.User? passedUser; // Data of user which we are showing

  const ProfilePage({super.key, this.uid,this.passedUser});

  @override
  State<StatefulWidget> createState() =>  _ProfilePageState();

}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _emailController =  TextEditingController();
  bool edit = false;
  bool search = false;
  bool friendAdded = false;
  bool myProfile = false; // Variable that tells us if we are viewing our own profile or not
  bool loaded = false;  // This tells us if we loaded a user
  model.User? user; // User which we are showing
  model.User? userBeforeChange;
  List<String> randomFriends = [];


  @override
  void initState(){
    super.initState();
    initialize();
  }

  void initialize(){
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
      return;
    }

    randomFriends.addAll(  // Get random friends
      getRandomFriends(AppData.currentUser?.friendsUid ?? [], 6),
    );

    if (widget.uid == AppData.currentUser?.uid) { // check if this profile is my profile
      myProfile = true;
    }
    // If it is not our profile check if user is not our friend or is not added to friend

  }

  Future<void> initializeAsync()  async{
    // Load user data
    if (widget.uid == AppData.currentUser?.uid) { // check if this profile is my profile
      user = AppData.currentUser;
      loaded = true;
    }else if(widget.passedUser != null){
      user = widget.passedUser;
      loaded = true;
    }else if(widget.uid != null){
      user = await UserService.fetchUser(widget.uid!);
      if(user != null){
        loaded = true;
      }else{
        loaded = false;
      }
      }
    else{
      loaded = false;
    }

    if(loaded == true){ // Sync with textfields
      _firstNameController.text = user!.firstName;
      _lastNameController.text = user!.lastName;
      userBeforeChange = UserService.cloneUserData(user!);
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
          backgroundColor: AppColors.alertDialogColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
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
                // Cancel button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor:AppColors.gray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                SizedBox(width: AppUiConstants.horizontalSpacingButtons),
                // Delete button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor:AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // close dialog
                      if(await UserService.deleteUserFromFirestore()){
                        AppUtils.showMessage(context, "User account deleted successfully");
                      }
                      UserService.signOutUser();
                    },
                    child: const Text("Delete my account"),
                  ),
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
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/start',(Route<dynamic> route) => false,
                    );
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
  void onEditFinished(BuildContext context)async  {
    if (!UserService.usersEqual(userBeforeChange!, user!)){
      setState(() {
        edit = false;
      });
    }else{ // Update user if there are changes
      model.User? res = await UserService.updateUser(user!);
      if(res == null){
        if(mounted)
          AppUtils.showMessage(context, "Error updating user");
      }else{
        AppUtils.showMessage(context, "User updated successfully");
      }
    }
  }

  void onPressedAddFriend() async {
    bool added = await UserService.actionToUsers(FirebaseAuth.instance.currentUser?.uid ?? "", user!.uid, UserAction.inviteToFriends);
    if(added){

    }
  }

  // Init fields


  @override
  Widget build(BuildContext context) {
    if(loaded ==  false){
        return NoItemsMsg(textMessage: "No user data");
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(myProfile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Edit button
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
                            if (edit) {
                              onEditFinished(context);
                            }
                            edit = !edit;
                          });
                        },
                      ),
                    ],
                  ),

                // If this is not my profile, show button add friends
                if(!myProfile)
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red),
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: Colors.white24,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      onPressed: () => addFriend(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Add friend",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          // TODO icon to change
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.add_circle, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
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
                                controller: _firstNameController,
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
                                controller: _lastNameController,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Friends: ${user?.friendsUid.length ?? 0}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),

                    // TODO To test
                    // Pick up to 6 random friends
                    if ((user?.friendsUid.isNotEmpty ?? false))
                      Row(
                        children: [
                          ...getRandomFriends(user!.friendsUid, 3).map(
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

                // TODO
                //Run Stats
                // Container(
                //   child: ,
                // )

                // Log out button
                SizedBox(height: 20),

                if(!edit)
                  SizedBox(
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
                      onPressed: () => logoutButtonPressed(context),
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
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.5,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red),
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
