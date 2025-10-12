import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';

import '../../../common/utils/utils.dart';

class ActivityChoose extends StatefulWidget {
  final String currentActivity;

  ActivityChooseState createState() => ActivityChooseState();

  const ActivityChoose({super.key, required this.currentActivity});
}

class ActivityChooseState extends State<ActivityChoose> {
  final TextEditingController _newActivityController = TextEditingController();
  int _selectedActivity = 0;
  bool addingEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchUserActivities();
    setCurrentlySelectedActivity();
  }

  void setCurrentlySelectedActivity() {
    if (AppData.currentUser == null ||
        AppData.currentUser?.activityNames == null) {
      return;
    }

    String current = widget.currentActivity; // the string you want to find
    int index = AppData.currentUser!.activityNames!.indexOf(current);

    if (index != -1) {
      setState(() {
        _selectedActivity = index; // set your selected index
      });
    } else {
      // string not found
      _selectedActivity = 0;
    }
  }

  void onActivityTap(int index) {
    setState(() {
      _selectedActivity = index;
      addingEnabled = false;
    });
  }

  // Todo export function to fetch user activities
  Future<void> fetchUserActivities() async {
    // If list is read, do not fetch it
    if (AppData.currentUser != null &&
        AppData.currentUser?.activityNames != null) {
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User need to log again
        FirebaseAuth.instance.signOut();
        // Push to start page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => StartPage()),
          (route) => false,
        );
        return; // No logged-in user
      }

      // TODO add with no internet and saving it to local prefs

      final uid = user.uid;

      // Fetch user document
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey("activityNames")) {
          if (AppData.currentUser != null &&
              AppData.currentUser!.activityNames != null) {
            setState(() {
              AppData.currentUser?.activityNames = List<String>.from(
                data["activityNames"],
              );
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching activity: $e");
    }
  }

  // Adding new activity
  void addNewActivity() {
    if (AppData.currentUser == null ||
        AppData.currentUser?.activityNames == null) {
      return;
    }

    // Check if this text controller is not empty
    if (_newActivityController.text.trim().isEmpty) {
      // TODO Make this messenger look better
      AppUtils.showMessage(context, "Activity name cannot be empty");
      return;
    }

    if (AppData.currentUser?.activityNames?.contains(
          _newActivityController.text.trim(),
        ) ??
        false) {
      AppUtils.showMessage(context, "Activity is already on the list");
      return;
    }

    setState(() {
      AppData.currentUser?.activityNames?.add(
        _newActivityController.text.trim(),
      );
      _newActivityController.text = "";
    });

    AppUtils.showMessage(context, "Activity added to list");
    addingEnabled = false;
    UserService.updateUser(AppData.currentUser!);  // Save activity data to firestore
  }

  /// Delete activity from list
  void deleteActivity(int index) {
    setState(() {
      AppData.currentUser?.activityNames?.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // When activities are not loaded
    if (AppData.currentUser?.activityNames == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Choose your activity typee:",
            style: AppTextStyles.PageHeaderTextStyle.copyWith(),
          ),
          centerTitle: true,
        ),
        backgroundColor: AppColors.pageHeaderColor,

        body: Center(child: CircularProgressIndicator()), // Loading state
      );
    }


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop,String? result)async {
        if(!didPop){
          if (AppData.currentUser?.activityNames?.isNotEmpty ?? false) {
            Navigator.pop(context,AppData.currentUser!.activityNames![_selectedActivity]);
          }else{
            Navigator.pop(context,"Unknown");
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Choose your activity type:",
            style: AppTextStyles.PageHeaderTextStyle.copyWith(),
          ),
          centerTitle: true,
          backgroundColor: AppColors.pageHeaderColor,
        ),
        floatingActionButtonLocation: CustomFabLocation(
          xOffset: 30,
          yOffset: 60,
        ),

        floatingActionButton: !addingEnabled
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => {
                  setState(() {
                    addingEnabled = !addingEnabled;
                  }),
                },
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                  weight: 2000,
                ),
              )
            : null,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // ensures taps are detected even on empty spaces
          onTap: () {
            FocusScope.of(context).unfocus(); // removes focus from TextField
            setState(() {
              addingEnabled = false; // optionally disable adding
            });
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background-first.jpg"),
                fit: BoxFit.cover,
                // Darkening
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.25),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: AppData.currentUser?.activityNames?.length,
                      itemBuilder: (context, index) {
                        bool isSelected =
                            AppData.currentUser!.activityNames![index] ==
                            AppData
                                .currentUser!
                                .activityNames![_selectedActivity];
                        return ListTile(
                          title: Text(
                            AppData.currentUser!.activityNames![index]
                                .toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.green : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: isSelected ? 1.5 : 1,
                            ),
                          ),
                          onTap: isSelected
                              ? () => ()
                              : () => onActivityTap(index),
                          selected:
                              AppData.currentUser!.activityNames![index] ==
                              widget.currentActivity,
                          trailing: IconButton(
                            onPressed: isSelected ? () => () : () => deleteActivity(index),
                            icon: isSelected
                                ? Icon(Icons.check, color: Colors.green)
                                : Icon(Icons.delete, color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                  if (addingEnabled)
                    Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: TextField(
                        controller: _newActivityController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: "Your new activity name",
                          fillColor: Colors.black.withValues(alpha: 0.4),
                          filled: true,
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white24,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  if (addingEnabled)
                    Padding(
                      padding: EdgeInsets.only(top: 8,bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Add new activity",
                          onPressed: addNewActivity,
                          backgroundColor: AppColors.primary,
                          gradientColors: [
                            Color(0xFFFFA726), // Light Orange
                            Color(0xFFFF5722),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
