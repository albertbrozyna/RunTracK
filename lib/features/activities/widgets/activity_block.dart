import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/utils/utils.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/stat_card.dart';

class ActivityBlock extends StatefulWidget {
  final String firstName;
  final String lastName;
  final Activity activity;
  final double titleFontSizeBlock = 14;
  final double valueFontSizeBlock = 14;
  final double innerPaddingBlock = 10;
  final double blockWidth = 120;
  final double blockHeight = 100;
  final double iconSize = 26;
  final Function(Activity) onActivityUpdated;

  const ActivityBlock({super.key, required this.activity, String? firstName, String? lastName,required this.onActivityUpdated})
    : firstName = firstName ?? "",
      lastName = lastName ?? "";

  @override
  State<ActivityBlock> createState() => _ActivityBlockState();
}

class _ActivityBlockState extends State<ActivityBlock> {
  late final ScrollController _scrollController = ScrollController();
  String? firstname;
  String? lastname;
  String? profilePhotoUrl;
  bool readonly = true;
  bool edit = false;
  final MapController _mapController = MapController();

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
  }

  Future<void> initializeAsync() async {
    if (widget.firstName.isEmpty || widget.lastName.isEmpty) {
      // If there is no name and last name fetch it from firestore
      return UserService.fetchUserForBlock(widget.activity.uid)
          .then((user) {
            if (!mounted) return;
            setState(() {
              if (user != null) {
                firstname = user.firstName;
                lastname = user.lastName;
              } else {
                firstname = "Deleted";
                lastname = "User";
              }
            });
          })
          .catchError((error) {
            print("Error fetching user data: $error");
            if (!mounted) return;
            setState(() {
              firstname = "User";
              lastname = "Unknown";
            });
          });
    }
  }


  bool _isNavigating = false;
  /// On activity block tap
  void onTapBlock(BuildContext context) async{
    if(_isNavigating){
      return;
    }
    _isNavigating = true;
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.activitySummary,
      arguments: {
        "activity": widget.activity,
        "readOnly": readonly,
        "editMode": edit,
        "firstName": firstname,
        "lastName": lastname,
      },
    );

    if(result != null && result is Activity){
      widget.onActivityUpdated(result);
    }

    _isNavigating = false;
  }

  @override
  void didUpdateWidget(covariant ActivityBlock oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activity.trackedPath != oldWidget.activity.trackedPath) {
      if (widget.activity.trackedPath?.isNotEmpty ?? false) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            AppUtils.fitMapToPath(widget.activity.trackedPath!, _mapController);
          }
        });
      }
    }
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
                        backgroundImage: AssetImage(AppImages.defaultProfilePhoto) as ImageProvider,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (widget.activity.startTime != null)
                          Text(
                            "Time: ${DateFormat('dd-MM-yyyy hh:mm').format(widget.activity.startTime!)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title on top
                      if (widget.activity.title != null && widget.activity.title!.isNotEmpty)
                        Text(
                          widget.activity.title!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
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
                                    value: ActivityService.formatElapsedTimeFromSeconds(
                                      widget.activity.elapsedTime!,
                                    ),
                                    icon: Icon(Icons.timer, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.totalDistance != null)
                                  StatCard(
                                    title: "Distance",
                                    value:
                                        '${(widget.activity.totalDistance! / 1000).toStringAsFixed(2)} km',
                                    icon: Icon(Icons.social_distance),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.pace != null)
                                  StatCard(
                                    title: "Pace",
                                    value: AppUtils.formatPace(widget.activity.pace!),
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
                                    title: "Elevation gain",
                                    value: '${widget.activity.elevationGain?.toStringAsFixed(0)} m',
                                    icon: Icon(Icons.terrain, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.activity.elevationGain != null)
                                  StatCard(
                                    title: "Elevation loss",
                                    value: '${widget.activity.elevationLoss?.toStringAsFixed(0)} m',
                                    icon: Icon(Icons.terrain, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                StatCard(
                                  title: "Visibility",
                                  value: widget.activity.visibility.name.toString(),
                                  icon: Icon(Icons.remove_red_eye_rounded, size: widget.iconSize),
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              widget.activity.trackedPath != null &&
                                  widget.activity.trackedPath!.isNotEmpty
                              ? widget.activity.trackedPath!.first
                              : LatLng(AppConstants.defaultLat, AppConstants.defaultLon),
                          // default location
                          onMapReady: () async {
                            // Delay to load a tiles properly
                            Future.delayed(const Duration(milliseconds: 100), () {
                              AppUtils.fitMapToPath(
                                widget.activity.trackedPath ?? [],
                                _mapController,
                              );
                            });
                          },
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
                              if (widget.activity.trackedPath != null &&
                                  widget.activity.trackedPath!.isNotEmpty)
                                Marker(
                                  point: widget.activity.trackedPath!.first,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.location_pin, color: Colors.green, size: 40),
                                ),
                              if (widget.activity.trackedPath != null &&
                                  widget.activity.trackedPath!.length > 1)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
