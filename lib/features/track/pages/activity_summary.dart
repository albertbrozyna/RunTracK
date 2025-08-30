import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';
import 'package:run_track/theme/ui_constants.dart';

import 'activity_choose.dart';

class ActivitySummary extends StatefulWidget {
  final List<LatLng> trackedPath;
  final double totalDistance;
  final Duration elapsedTime;
  final String activityType;

  const ActivitySummary({
    Key? key,
    required this.trackedPath,
    required this.totalDistance,
    required this.elapsedTime,
    required this.activityType,
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

  @override
  void initState() {
    super.initState();
    setState(() {
      activityController.text = widget.activityType;
    });
  }

  Future<void> handleSaveActivity() async {
    // Activity data
    // TODO add date when user runs it
    final activityData = {
      'totalDistance': widget.totalDistance,
      'elapsedTime': widget.elapsedTime.inSeconds,
      'trackedPath': widget.trackedPath
          .map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude})
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // TODO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save your activity')),
      );
      return;
    }

    try {
      // Save activity to database
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("activities")
          .add(activityData);
      // TODO ADD comback to a track screen

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
        title: Text("Activity summary"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Time: ${AppUtils.formatDuration(widget.elapsedTime)}',
                  style: AppTextStyles.heading.copyWith(),
                ),
                SizedBox(width: 15),

                Text(
                  'Distance: ${widget.totalDistance}',
                  style: AppTextStyles.heading.copyWith(),
                ),
              ],
            ),
            // Activity type
            TextField(
              controller: activityController,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppUiConstants.borderRadiusTextFields,
                ),
                label: Text("Activity type"),
                suffixIcon: Padding(
                  padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
                  child: IconButton(
                    onPressed: () => onTapActivity(),
                    icon: Icon(Icons.list),
                  ),
                ),
              ),
            ),
            if(widget.trackedPath.isNotEmpty)
              SizedBox(
                height: AppUiConstants.kTextFieldSpacing,
              ),
            if (widget.trackedPath.isNotEmpty)

              Expanded(
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
            SizedBox(
              height: AppUiConstants.kTextFieldSpacing,
            ),
            // TODO Change color after saving activity
            if (!activitySaved)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: activitySaved ? "Activity saved" : "Save activity",
                  onPressed: activitySaved ? null : () => handleSaveActivity(),
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
    );
  }
}
