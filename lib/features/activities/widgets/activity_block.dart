import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/services/activity_service.dart';

import '../../../services/user_service.dart';
import '../../track/pages/activity_summary.dart';
import '../../track/widgets/stat_card.dart';

class ActivityBlock extends StatefulWidget {
  final String? profilePhotoUrl;
  final String firstName;
  final String lastName;
  final Activity activity;
  final double titleFontSizeBlock = 14;
  final double valueFontSizeBlock = 14;
  final double innerPaddingBlock = 10;
  final double blockWidth = 120;
  final double blockHeight = 100;
  final double iconSize = 26;

  const ActivityBlock({super.key, required this.firstName, required this.lastName, required this.activity, this.profilePhotoUrl});

  @override
  _ActivityBlockState createState() => _ActivityBlockState();
}

class _ActivityBlockState extends State<ActivityBlock> {
  late final ScrollController _scrollController = ScrollController();
  String? firstname;
  String? lastname;
  String? profilePhotoUrl;
  bool readonly = true;
  bool edit = false;

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    if (FirebaseAuth.instance.currentUser?.uid == widget.activity.uid) {
      readonly = false; // Allow to edit own activities
      edit = true;
    }
    firstname = widget.firstName;
    lastname = widget.lastName;
    profilePhotoUrl = widget.profilePhotoUrl;
  }

  Future<void> initializeAsync() async {
    if (widget.firstName.isEmpty || widget.lastName.isEmpty) {
      // If there is no name and last name fetch it from firestore
      return UserService.fetchUserForActivity(widget.activity.uid)
          .then((user) {
            setState(() {
              firstname = user?.firstName;
              lastname = user?.lastName;
              profilePhotoUrl = user?.profilePhotoUrl;
            });
          })
          .catchError((error) {
            print("Error fetching user data: $error");
          });
    }
  }

  /// On activity block tap
  void onTapBlock(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          activityData: widget.activity,
          readonly: readonly,
          editMode: edit,
          firstName: widget.firstName,
          lastName: widget.lastName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () => onTapBlock(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 1, style: BorderStyle.solid),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Header with name, date  and profile page
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile photo
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: widget.profilePhotoUrl != null
                            ? NetworkImage(widget.profilePhotoUrl!)
                            : AssetImage('assets/DefaultProfilePhoto.png') as ImageProvider,
                      ),
                    ),
                    SizedBox(width: 10),

                    // First name and date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$firstname $lastname",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (widget.activity.startTime != null)
                          Text(
                            "Time: ${DateFormat('dd-MM-yyyy hh:mm').format(widget.activity.startTime!)}",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title on top
                      if (widget.activity.title != null && widget.activity.title!.isNotEmpty)
                        Text(
                          widget.activity.title!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),

                      SizedBox(height: 4),

                      // Stats on the left and map on the right
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          thickness: 4,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 10,
                              children: [
                                if (widget.activity.elapsedTime != null)
                                  StatCard(
                                    title: "Time",
                                    value: ActivityService.formatElapsedTimeFromSeconds(widget.activity.elapsedTime!),
                                    icon: Icon(Icons.timer, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.totalDistance != null)
                                  StatCard(
                                    title: "Distance",
                                    value: '${(widget.activity.totalDistance! / 1000).toStringAsFixed(2)} km',
                                    icon: Icon(Icons.social_distance),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.totalDistance != null)
                                  StatCard(
                                    title: "Pace",
                                    value: widget.activity.pace.toString(),
                                    icon: Icon(Icons.man, size: widget.iconSize),
                                  ),
                                if (widget.activity.calories != null)
                                  StatCard(
                                    title: "Calories",
                                    value: '${widget.activity.calories?.toStringAsFixed(0)} kcal',
                                    icon: Icon(Icons.local_fire_department, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.avgSpeed != null)
                                  StatCard(
                                    title: "Avg Speed",
                                    value: '${widget.activity.avgSpeed?.toStringAsFixed(1)} km/h',
                                    icon: Icon(Icons.speed, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.steps != null)
                                  StatCard(
                                    title: "Steps",
                                    value: widget.activity.steps.toString(),
                                    icon: Icon(Icons.directions_walk, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.elevationGain != null)
                                  StatCard(
                                    title: "Elevation",
                                    value: '${widget.activity.elevationGain?.toStringAsFixed(0)} m',
                                    icon: Icon(Icons.terrain, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Map with activity
                      ),
                      // Optional Description under stats
                    ],
                  ),
                ),

                if (widget.activity.trackedPath?.isNotEmpty ?? false)
                  ClipRRect(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.activity.trackedPath != null && widget.activity.trackedPath!.isNotEmpty
                              ? widget.activity.trackedPath!.first
                              : LatLng(37.7749, -122.4194),
                          // default location
                          onTap: (tapPosition, point) {
                            onTapBlock(context);
                          },
                          initialZoom: 15.0,
                          interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.runtrack',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: widget.activity.trackedPath ?? [],
                                // draw the path
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              if (widget.activity.trackedPath != null && widget.activity.trackedPath!.isNotEmpty)
                                Marker(
                                  point: widget.activity.trackedPath!.first,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.location_pin, color: Colors.green, size: 40),
                                ),
                              if (widget.activity.trackedPath != null && widget.activity.trackedPath!.length > 1)
                                Marker(
                                  point: widget.activity.trackedPath!.last,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.flag, color: Colors.red, size: 40),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Photos from the run
                if (widget.activity.photos.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      // From left to right
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.activity.photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(widget.activity.photos[index], width: 120, height: 120, fit: BoxFit.cover),
                          ),
                        );
                      },
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
