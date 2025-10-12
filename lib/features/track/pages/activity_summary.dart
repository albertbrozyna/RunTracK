import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/add_photos.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:intl/intl.dart';
import '../widgets/stat_card.dart';
import 'activity_choose.dart';
import 'package:run_track/common/enums/visibility.dart' as vb;
import 'package:run_track/services/preferences_service.dart';
import 'package:run_track/theme/preference_names.dart';

class ActivitySummary extends StatefulWidget {
  final Activity activityData;

  const ActivitySummary({
    super.key,
    required this.activityData,
  });

  @override
  _ActivitySummaryState createState() => _ActivitySummaryState();
}

class _ActivitySummaryState extends State<ActivitySummary> {
  bool activitySaved = false;   // This var tells us if activity is saved
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController activityController = TextEditingController();
  Activity? activity; // activity data
  bool readOnly = false;

  // TODO idea save last visibility as preferences
  vb.Visibility _visibility = vb.Visibility.me;

  final List<String> visibilityOptions = ['ME', 'FRIENDS', 'EVERYONE'];

  List<XFile> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    // Formatted startTime of the activity
    final formattedDate = widget.activityData.startTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(widget.activityData.startTime!)
        : '';
    setState(() {
      activityController.text = widget.activityData.activityType ?? "Unknown";
      titleController.text = '${activityController.text} $formattedDate';
    });

    // Check if it is our activity or we are only showing it
    if(widget.activityData.uid != AppData.currentUser?.uid){
      readOnly = true;
    }
  }

  /// Set last visibility used by user
  Future<void>setLastVisibility() async{
    String? visibilityS = await PreferencesService.loadString(PreferenceNames.lastVisibility);

    if(visibilityS != null && visibilityS.isNotEmpty){
      if(visibilityS == 'me'){
        setState(() {
          _visibility = vb.Visibility.me;
        });
      }else if(visibilityS == 'friends'){
        setState(() {
          _visibility = vb.Visibility.friends;
        });
      }else if(visibilityS == 'everyone'){
        setState(() {
          _visibility = vb.Visibility.everyone;
        });
      }
    }
  }

  Future<void>saveLastVisibility() async{
    PreferencesService.saveString(PreferenceNames.lastVisibility, _visibility.toString());
  }


  /// Init async data
  Future<void> initAsync() async{
    setLastVisibility();
  }


  Future<void> handleSaveActivity() async {
    // Photos from activity
    List<String> uploadedUrls = [];
    if(AppData.images){ // If images are enabled in app
      for (var image in _pickedImages) {
        final ref = FirebaseStorage.instance.ref().child(
          'users/${AppData.currentUser?.uid}/activities/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
        );
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        uploadedUrls.add(url);
      }
    }

    // Activity data
    Activity userActivity = Activity(
      uid: widget.activityData.uid,
      activityType: activityController.text.trim(),
      description: descriptionController.text.trim(),
      title: titleController.text.trim(),
      totalDistance: widget.activityData.totalDistance,
      elapsedTime: widget.activityData.elapsedTime,
      visibility: _visibility,
      startTime: widget.activityData.startTime,
      trackedPath: widget.activityData.trackedPath,
      photos: uploadedUrls
    );

    // Save activity to database
    bool saved = await ActivityService.saveActivity(userActivity);
    if (saved) {
      AppData.trackState.deleteFile(); // Delete a file from local store if it is saved
      saveLastVisibility(); /// Save last visibility to local prefs
      setState(() {
        activitySaved = true;
      });
    } else {
      if(mounted){
        AppUtils.showMessage(context, 'Failed to save activity');
      }
    }
  }

  /// Ask if we are sure if we want to leave a page without saving
  void leavePage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Close by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Warning",
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "You haven't saved this activity yet.\n\n"
                "If you leave now, your activity will be lost.\n\n"
                "Are you sure you want to leave?",
            textAlign: TextAlign.center,
          ),
          alignment: Alignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                SizedBox(width: AppUiConstants.horizontalSpacingButtons),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                      AppData.trackState.deleteFile(); // Delete a file from local store if user wants to exit

                    Navigator.of(context).pop(); // Two times to close dialog and screen
                    Navigator.of(context).pop();
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  /// Method invoked when user wants to select change activity
  void onTapActivity() async {
    final selectedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityChoose(currentActivity: activityController.text.trim()),
      ),
    );
    // If the user selected something, update the TextField
    if (selectedActivity != null && selectedActivity.isNotEmpty) {
      activityController.text = selectedActivity;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!UserService.isUserLoggedIn()){
    UserService.signOutUser();
    Navigator.of(context).pushNamedAndRemoveUntil('/start',(route) => false);
    }


    return PopScope(
      canPop: false,
    onPopInvokedWithResult: (bool didPop,String? result)async {
      if(!didPop){
        if (!readOnly && !activitySaved) {
            leavePage(context);
        }else{
          Navigator.pop(context,null);
        }
      }
    },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text(
            "Activity summary",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
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
            padding: EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
            child: SingleChildScrollView(
              child: Column(
                children: [

                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Title
                  TextField(
                    readOnly: readOnly,
                    controller: titleController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24, width: 1),
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      label: Text("Title", style: TextStyle(color: Colors.white)),
                      labelStyle: TextStyle(fontSize: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Description
                  TextField(
                    readOnly: readOnly,
                    maxLines: 3,
                    controller: descriptionController,
                    decoration: InputDecoration(
                      // Normal border
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24, width: 1),
                      ),
                      label: Text(
                        "Description",
                        style: TextStyle(color: Colors.white),
                      ),
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      filled: true,
                    ),
                    style: TextStyle(color: Colors.white),
                  ),

                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                  // Activity type
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.left,
                          controller: activityController,
                          readOnly: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            label: Text(
                              "Activity type",
                              style: TextStyle(color: Colors.white),
                            ),
                            suffixIcon: Padding(
                              padding: EdgeInsets.all(
                                AppUiConstants.paddingTextFields,
                              ),
                              child: IconButton(
                                onPressed: () => onTapActivity(),
                                icon: Icon(Icons.list, color: Colors.white),
                              ),
                            ),
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            filled: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      // Visibility
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            iconTheme: IconThemeData(
                              color: Colors.white,
                            ),
                          ),
                          child: DropdownMenu(
                            enabled: !readOnly,
                            initialSelection: _visibility,
                            label: Text(
                              "Visibility",
                              style: TextStyle(color: Colors.white),
                            ),
                            textStyle: TextStyle(color: Colors.white),
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                              ),
                            ),
                            width: double.infinity,
                            textAlign: TextAlign.left,
                            // Selecting visibility
                            onSelected: (vb.Visibility? visibility) {
                              setState(() {
                                if (visibility != null) {
                                  _visibility = visibility;
                                }
                              });
                            },
                            // Icon
                            trailingIcon: Icon(
                              color: Colors.white,
                              Icons.arrow_drop_down
                            ),
                            selectedTrailingIcon: Icon(
                              color: Colors.white,
                              Icons.arrow_drop_up
                            ),

                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(AppColors.dropdownEntryBackground),
                              alignment: Alignment.bottomLeft,
                            ),
                            dropdownMenuEntries:
                                <DropdownMenuEntry<vb.Visibility>>[
                                  DropdownMenuEntry(
                                    value: vb.Visibility.me,
                                    label: "Only Me",
                                    // style: ButtonStyle(
                                    //   backgroundColor:
                                    // ),

                                  ),
                                  DropdownMenuEntry(
                                    value: vb.Visibility.friends,
                                    label: "Friends",
                                  ),
                                  DropdownMenuEntry(
                                    value: vb.Visibility.everyone,
                                    label: "Everyone",
                                  ),
                                ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  IntrinsicHeight(

                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 6,
                        children: [
                        // Time
                          if(widget.activityData.elapsedTime != null)
                            StatCard(title: "Time", value: ActivityService.formatElapsedTimeFromSeconds(widget.activityData.elapsedTime!), icon: Icon(Icons.timer)),
                          if(widget.activityData.totalDistance != null)
                            StatCard(title:"Distance",value: '${(widget.activityData.totalDistance! / 1000).toStringAsFixed(2)} km', icon:Icon(Icons.social_distance)),
                          if(widget.activityData.totalDistance != null)
                            StatCard(title:"Pace",value: widget.activityData.pace.toString(),icon: Icon(Icons.man)),
                          if(widget.activityData.calories != null)
                            StatCard(title:"Calories",value: '${widget.activityData.calories?.toStringAsFixed(0)} kcal',icon:  Icon(Icons.local_fire_department)),
                          if(widget.activityData.avgSpeed != null)
                            StatCard(title:"Avg Speed",value: '${widget.activityData.avgSpeed?.toStringAsFixed(1)} km/h',icon: Icon(Icons.speed)),
                          if(widget.activityData.steps != null)
                            StatCard(title:"Steps",value: widget.activityData.steps.toString(), icon:Icon(Icons.directions_walk)),
                          if(widget.activityData.elevationGain != null)
                            StatCard(title:"Elevation",value: '${widget.activityData.elevationGain?.toStringAsFixed(0)} m',icon: Icon(Icons.terrain)),
                      ]
              ),
                    ),
                  ),

                  // Flutter map if there is a path
                  if (widget.activityData.trackedPath?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0,bottom: 10.0),
                      child: ClipRRect(
                       borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: widget.activityData.trackedPath?.first ?? LatLng(0,0),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.runtrack',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: widget.activityData.trackedPath ?? [],
                                    color: Colors.blue,
                                    strokeWidth: 4.0,

                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: widget.activityData.trackedPath?.first ?? LatLng(0, 0),
                                    width: 40,
                                    height: 40,
                                    child: Icon(Icons.flag, color: Colors.green),
                                  ),
                                  if (widget.activityData.trackedPath != null && widget.activityData.trackedPath!.length > 1)                                     Marker(
                                      point: widget.activityData.trackedPath?.last ?? LatLng(0, 0),
                                      width: 40,
                                      height: 40,
                                      child: Icon(Icons.stop, color: Colors.red),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Photos section
                    AddPhotos(
                      onlyShow: false,
                      active: true,
                      showSelectedPhotos: true,
                      onImagesSelected: (images) {
                        _pickedImages = images;
                      },
                    ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  if(!readOnly)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: activitySaved ? "Activity saved" : "Save activity",
                        onPressed: activitySaved
                            ? null
                            : () => handleSaveActivity(),
                        gradientColors: [
                          activitySaved ? Colors.grey :Color(0xFFFFB74D),
                          activitySaved ? Colors.grey :Color(0xFFFF9800),
                          activitySaved ? Colors.grey :Color(0xFFF57C00),
                        ],
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
