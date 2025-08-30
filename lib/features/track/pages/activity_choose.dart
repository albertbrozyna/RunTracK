import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';

class ActivityChoose extends StatefulWidget {
  ActivityChooseState createState() => ActivityChooseState();
}

class ActivityChooseState extends State<ActivityChoose> {
  TextEditingController _newActivityController = new TextEditingController();
  int _selectedActivity = 0;
  late List<String> activities;

  void onActivityTap(int index) {
    setState(() {
      _selectedActivity = index;
    });
  }

  // Todo export function to fetch user activities
  Future<void> fetchUserActivities() async{
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        activities = AppUtils.getDefaultActivities();
        return; // No logged-in user
      }
      final uid = user.uid;

      // Fetch user document
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey("activities")) {
          activities = List<String>.from(data["activities"]);
        }
      }
    } catch (e) {
      print("Error fetching activity: $e");
    }
  }

  void addNewActivity(){
    // Check if this text controller is not empty
    if(_newActivityController.text.trim().isEmpty){ // TODO Make this messenger look better
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        "Activity name cannot be empty"
      )));
      return;
    }

    if(activities.contains(_newActivityController.text.trim() )){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          "Activity is already on the list"
      )));
      return;
    }

    setState(() {
      activities.add(_newActivityController.text.trim());
      _newActivityController.text = "";
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        "Activity added to list"
    )));
  }

  void deleteActivity(int index){
    setState(() {
      activities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(   onPopPage: (route, result) {
      // Called when user tries to pop this route
      // Return true to allow pop, false to prevent
      print("Pop attempted!");
      // Optionally return a value to previous screen
      Navigator.pop(context, "myResult");
      return false; // prevent default, we manually popped
    }, child: Scaffold(
        appBar: AppBar(title: Text("Choose your activity type:")),
        body: Column(
          children: [
            ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(activities[index]),
                  onTap: () => onActivityTap(index),
                  trailing: IconButton(onPressed: () => deleteActivity(index), icon: Icon(Icons.delete)),
                );
              },
            ),
            TextField(
              controller: _newActivityController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Your new activity name",
              ),
            ),
            CustomButton(text: "Add new activity", onPressed: addNewActivity)
          ],
        )
    ),);
  }
}
