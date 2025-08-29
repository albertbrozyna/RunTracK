import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/custom_button.dart';

class ActivityChoose extends StatefulWidget {
  ActivityChooseState createState() => ActivityChooseState();
}

class ActivityChooseState extends State<ActivityChoose> {
  TextEditingController _newActivityController = new TextEditingController();
  int _selectedActivity = 0;
  List<String> activities = [
    "Running",
    "Jogging",
    "Swimming",
    "Playing football",
    "Gym",
  ];

  void onActivityTap(int index) {
    setState(() {
      _selectedActivity = index;
    });
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
    return Scaffold(
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
    );
  }
}
