import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/start/pages/start_page.dart';

class ActivityChoose extends StatefulWidget {
  final String currentActivity;

  ActivityChooseState createState() => ActivityChooseState();

  const ActivityChoose({Key? key, required this.currentActivity})
    : super(key: key);
}

class ActivityChooseState extends State<ActivityChoose> {
  TextEditingController _newActivityController = new TextEditingController();
  int _selectedActivity = 0;

  @override
  void initState() {
    super.initState();
    fetchUserActivities();
  }

  void onActivityTap(int index) {
    setState(() {
      _selectedActivity = index;
    });
  }

  // Todo export function to fetch user activities
  Future<void> fetchUserActivities() async {
    // If list is read, do not fetch it
    if (AppData.currentUser != null && AppData.currentUser?.activityNames != null) {
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
        if (data != null && data.containsKey("activities")) {
          setState(() {
            AppData.currentUser?.activityNames = List<String>.from(data["activities"]);
          });
        }
      }
    } catch (e) {
      print("Error fetching activity: $e");
    }
  }

  void addNewActivity() {
    if (AppData.currentUser == null || AppData.currentUser?.activityNames == null) {
      return;
    }
    // Check if this text controller is not empty
    if (_newActivityController.text.trim().isEmpty) {
      // TODO Make this messenger look better
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Activity name cannot be empty")));
      return;
    }

    if (AppData.currentUser?.activityNames?.contains(_newActivityController.text.trim()) ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Activity is already on the list")),
      );
      return;
    }

    setState(() {
      AppData.currentUser?.activityNames?.add(_newActivityController.text.trim());
      _newActivityController.text = "";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Activity added to list")));
  }

  void deleteActivity(int index) {
    setState(() {
      AppData.currentUser?.activityNames?.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AppData.currentUser?.activityNames == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Choose your activity type:")),
        body: Center(child: CircularProgressIndicator()), // Loading state
      );
    }

    return WillPopScope(
      // TODO FIND A good approach with popScope
      onWillPop: () async {
        if (AppData.currentUser?.activityNames != null && (AppData.currentUser?.activityNames?.isNotEmpty ?? false)) {
          final selected = AppData.currentUser!.activityNames![_selectedActivity];
          Navigator.pop(context, selected);
        } else {
          Navigator.pop(context, null); // fallback
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Choose your activity type:")),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: AppData.currentUser?.activityNames?.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(AppData.currentUser!.activityNames![index]),
                    onTap: () => onActivityTap(index),
                    selected:
                        AppData.currentUser!.activityNames![index] ==
                        widget.currentActivity,
                    trailing: IconButton(
                      onPressed: () => deleteActivity(index),
                      icon: Icon(Icons.delete),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _newActivityController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: "Your new activity name"),
            ),
            CustomButton(text: "Add new activity", onPressed: addNewActivity),
          ],
        ),
      ),
    );
  }
}
