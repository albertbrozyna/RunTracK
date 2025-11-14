import 'package:flutter/material.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../widgets/fab_location.dart';


class ActivityChoose extends StatefulWidget {
  final String currentActivity;

  const ActivityChoose({super.key, required this.currentActivity});

  @override
  State<ActivityChoose> createState() => ActivityChooseState();
}

class ActivityChooseState extends State<ActivityChoose> {
  final TextEditingController _newActivityController = TextEditingController();
  late ValueNotifier<int> _selectedActivityNotifier;
  bool addingEnabled = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _newActivityController.dispose();
    _selectedActivityNotifier.dispose();
    super.dispose();
  }

  void initialize() {
    AuthService.instance.checkAppUseState(context);

    String current = widget.currentActivity;
    int index = AppData.instance.currentUser!.activityNames.indexOf(current);

    _selectedActivityNotifier = ValueNotifier<int>(index != -1 ? index : 0);
  }

  void onActivityTap(int index) {
    _selectedActivityNotifier.value = index;

    if (addingEnabled) {
      setState(() {
        addingEnabled = false;
      });
    }
  }

  // Adding new activity
  void addNewActivity() {
    if (_newActivityController.text.trim().isEmpty) {
      AppUtils.showMessage(context, "Activity name cannot be empty", messageType: MessageType.info);
      return;
    }
    if (AppData.instance.currentUser?.activityNames.contains(_newActivityController.text.trim()) ?? false) {
      AppUtils.showMessage(context, "Activity is already on the list", messageType: MessageType.info);
      return;
    }

    setState(() {
      AppData.instance.currentUser?.activityNames.add(_newActivityController.text.trim());
      _newActivityController.text = "";
    });

    AppUtils.showMessage(context, "Activity added to list", messageType: MessageType.success);
    addingEnabled = false;
    UserService.updateUser(AppData.instance.currentUser!);
  }

  /// Delete activity from list
  void deleteActivity(int index) {
    setState(() {
      AppData.instance.currentUser?.activityNames.removeAt(index);
    });
    UserService.updateUser(AppData.instance.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    if (AppData.instance.currentUser?.activityNames == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Choose your activity type:")),
        body: Center(child: CircularProgressIndicator()), // Loading state
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, String? result) async {
        if (!didPop) {
          if (AppData.instance.currentUser?.activityNames.isNotEmpty ?? false) {
            Navigator.pop(context, AppData.instance.currentUser!.activityNames[_selectedActivityNotifier.value]);
          } else {
            Navigator.pop(context, "Unknown");
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Choose your activity type:")),
        floatingActionButtonLocation: CustomFabLocation(xOffset: 30, yOffset: 60),
        floatingActionButton: !addingEnabled
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => {
                  setState(() {
                    addingEnabled = !addingEnabled;
                  }),
                },
                child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
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
          child: PageContainer(
            assetPath: AppImages.appBg5,
            child: Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _selectedActivityNotifier,
                    builder: (context, selectedActivity, child) {
                      return ListView.builder(
                        itemCount: AppData.instance.currentUser?.activityNames.length,
                        itemBuilder: (context, index) {
                          bool isSelected = index == selectedActivity;
                          return ListTile(
                            title: Text(
                              AppData.instance.currentUser!.activityNames[index].toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.green : Colors.white,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: isSelected ? 1.5 : 1,
                              ),
                            ),
                            onTap: isSelected ? () => () : () => onActivityTap(index),
                            selected: index == selectedActivity,
                            trailing: IconButton(
                              onPressed: isSelected ? () => () : () => deleteActivity(index),
                              icon: isSelected ? Icon(Icons.check, color: Colors.green) : Icon(Icons.delete, color: Colors.white),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (addingEnabled) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: TextFormField(
                      controller: _newActivityController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Your new activity name",
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      maxLines: 1,
                    ),
                  ),

                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  CustomButton(text: "Add new activity", onPressed: addNewActivity, backgroundColor: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
