import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/firestore_utils.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../common/utils/app_data.dart';

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
    required this.activityType
  }) : super(key: key);

  @override
  _ActivitySummaryState createState() => _ActivitySummaryState();
}

class _ActivitySummaryState extends State<ActivitySummary> {
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

    try {
      // If currentUser id is null fetch it and save to appData
      if (AppData.currentUserId == null) {
        await fetchCurrentUserAndSave();
      }
      // Save activity to database
      await FirebaseFirestore.instance
          .collection("users")
          .doc(AppData.currentUserId)
          .collection("activities")
          .add(activityData);
    } catch (e) {
      print('Error saving activity: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save activity')));
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
                  'Time: ${formatDuration(widget.elapsedTime)}',
                  style: AppTextStyles.heading.copyWith(),
                ),
                SizedBox(width: 15),

                Text(
                  'Distance: ${widget.totalDistance}',
                  style: AppTextStyles.heading.copyWith(),
                ),
              ],
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
              width: double.infinity,
              height: 50,
              child: CustomButton(
                text: "Save activity",
                onPressed: () => handleSaveActivity(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
