import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/models/activity.dart';

class ActivityBlock extends StatelessWidget {
  final String firstName;
  final String lastName;
  final Activity activity;

  const ActivityBlock({
      required this.firstName,
      required this.lastName,
      required this.activity
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Header with name, date  and profile page
          Row(
            children: [
              // Name and surname
              Text("$firstName $lastName"),
              // Date
              // TODO Think about it what if start time is null
              Text("${DateFormat('dd-MM-yyyy hh:mm').format(activity.startTime ?? DateTime.now())}"),
            ],
          ),
          // Title
          Row(children: [Text(activity.title ?? "")]),
          // Description
          Row(children: [Text(activity.description ?? "")]),

          // Photos from the run
          if (activity.photos.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                // From left to right
                scrollDirection: Axis.horizontal,
                itemCount: activity.photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        activity.photos[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Map with activity map
          FlutterMap(
            options: MapOptions(
              initialCenter: activity.trackedPath != null && activity.trackedPath!.isNotEmpty
                  ? activity.trackedPath!.first
                  : LatLng(37.7749, -122.4194), // default location
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.runtrack',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: activity.trackedPath ?? [], // draw the path
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (activity.trackedPath != null && activity.trackedPath!.isNotEmpty)
                    Marker(
                      point: activity.trackedPath!.first,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_pin, color: Colors.green, size: 40),
                    ),
                  if (activity.trackedPath != null && activity.trackedPath!.length > 1)
                    Marker(
                      point: activity.trackedPath!.last,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                ],
              )
            ],
          )



        ],
      ),
    );
  }
}
