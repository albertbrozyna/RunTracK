import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/add_photos.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';
import 'package:run_track/theme/ui_constants.dart';
import 'package:intl/intl.dart';
import 'activity_choose.dart';
import 'package:run_track/common/enums/visibility.dart' as vb;

class ActivitySummary extends StatefulWidget {
  final List<LatLng> trackedPath;
  final double totalDistance;
  final Duration elapsedTime;
  final String activityType;
  final DateTime? startTime;

  const ActivitySummary({
    Key? key,
    required this.trackedPath,
    required this.totalDistance,
    required this.elapsedTime,
    required this.activityType,
    required this.startTime,
  }) : super(key: key);

  @override
  _ActivitySummaryState createState() => _ActivitySummaryState();
}

class _ActivitySummaryState extends State<ActivitySummary> {
  // This var tells us if activity is saved
  bool activitySaved = false;
  TextEditingController titleController = new TextEditingController();
  TextEditingController descriptionController = new TextEditingController();
  TextEditingController notesController = new TextEditingController();
  TextEditingController activityController = new TextEditingController();

  // TODO idea save last visibility as preferences
  vb.Visibility _visibility = vb.Visibility.ME;

  final List<String> visibilityOptions = ['ME', 'FRIENDS', 'EVERYONE'];

  List<XFile> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    // Formatted startTime of the activity
    final formattedDate = widget.startTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(widget.startTime!)
        : '';
    setState(() {
      activityController.text = widget.activityType;
      titleController.text = '${widget.activityType} $formattedDate';
    });
  }

  Future<void> handleSaveActivity() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      // TODO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save your activity')),
      );
      FirebaseAuth.instance.signOut();
      return;
    }
    // Photos from activity
    List<String> uploadedUrls = [];
    for (var image in _pickedImages) {
      final ref = FirebaseStorage.instance.ref().child(
        'users/$uid/activities/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
      );
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      uploadedUrls.add(url);
    }
    // Activity data
    Activity userActivity = new Activity(
      activityType: widget.activityType,
      description: descriptionController.text.trim(),
      title: titleController.text.trim(),
      totalDistance: widget.totalDistance,
      elapsedTime: widget.elapsedTime.inSeconds.toInt(),
      visibility: _visibility.toString(),
      startTime: widget.startTime,
      trackedPath: widget.trackedPath,
      photos: uploadedUrls
    );

    // Save activity to database
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("activities")
          .add(userActivity.toMap());
      setState(() {
        activitySaved = true;
      });
    } catch (e) {
      print('Error saving activity: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save activity')));
    }
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
    return Scaffold(
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
            // Przyciemnienie zakładki
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
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Box na czas
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(height: 5),
                              Text(
                                AppUtils.formatDuration(widget.elapsedTime),
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Time",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Box na dystans
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.route, color: Colors.white, size: 28),
                              SizedBox(height: 5),
                              Text(
                                "${widget.totalDistance.toStringAsFixed(2)} km",
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Distance",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppUiConstants.kTextFieldSpacing),
                // Title
                TextField(
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
                SizedBox(height: AppUiConstants.kTextFieldSpacing),
                // Description
                TextField(
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

                SizedBox(height: AppUiConstants.kTextFieldSpacing),

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
                          textStyle: TextStyle(color: Colors.white),
                          label: Text(
                            "Visibility",
                            style: TextStyle(color: Colors.white),
                          ),
                          initialSelection: _visibility,

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
                            backgroundColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.8)),
                            alignment: Alignment.center,


                          ),
                          dropdownMenuEntries:
                              <DropdownMenuEntry<vb.Visibility>>[
                                DropdownMenuEntry(
                                  value: vb.Visibility.ME,
                                  label: "Only Me",
                                ),
                                DropdownMenuEntry(
                                  value: vb.Visibility.FRIENDS,
                                  label: "Friends",
                                ),
                                DropdownMenuEntry(
                                  value: vb.Visibility.EVERYONE,
                                  label: "Everyone",
                                ),
                              ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Flutter map if there is a path
                if (widget.trackedPath.isNotEmpty)
                  SizedBox(height: AppUiConstants.kTextFieldSpacing),
                if (widget.trackedPath.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          // TODO TO CHANGE THIS DEFAULT LOCATION TO LAST USER LOC
                          initialCenter: widget.trackedPath.first,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.runtrack',
                          ),
                          if (widget.trackedPath.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: widget.trackedPath,
                                  color: Colors.blue,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                          if (widget.trackedPath.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: widget.trackedPath.first,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.flag, color: Colors.green),
                                ),
                                Marker(
                                  point: widget.trackedPath.last,
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

                SizedBox(height: AppUiConstants.kTextFieldSpacing),
                // Photos section
                AddPhotos(
                  showSelectedPhots: true,
                  onImagesSelected: (images) {
                    _pickedImages = images;
                  },
                ),

                SizedBox(height: AppUiConstants.kTextFieldSpacing),

                // TODO Change color after saving activity
                if (!activitySaved)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: activitySaved ? "Activity saved" : "Save activity",
                      onPressed: activitySaved
                          ? null
                          : () => handleSaveActivity(),
                      gradientColors: [
                        Color(0xFFFFB74D),
                        Color(0xFFFF9800),
                        Color(0xFFF57C00),
                      ],
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
