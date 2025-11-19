import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_data.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
import 'package:run_track/features/competitions/data/models/result_record.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';
import 'package:run_track/features/track/presentation/widgets/competition_finish_banner.dart';

import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/preference_names.dart';
import '../../../../core/enums/visibility.dart' as enums;
import '../../../../core/models/activity.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/alert_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/models/track_state.dart';

class ActivitySummary extends StatefulWidget {
  final Activity activityData;
  final Competition? currentUserCompetition;
  final String firstName;
  final String lastName;
  final bool readonly;
  final bool editMode;

  const ActivitySummary({
    super.key,
    required this.activityData,
    this.firstName = '',
    this.lastName = '',
    bool? readonly,
    bool? editMode,
    this.currentUserCompetition,
  }) : readonly = readonly ?? true,
       editMode = editMode ?? false;

  @override
  State<ActivitySummary> createState() => _ActivitySummaryState();
}

class _ActivitySummaryState extends State<ActivitySummary> {
  bool activitySaved = false; // This var tells us if activity is saved
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController activityController = TextEditingController();
  late Activity passedActivity = widget.activityData;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  final List<String> visibilityOptions = ['ME', 'FRIENDS', 'EVERYONE'];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    AuthService.instance.checkAppUseState(context);

    setState(() {
      fullNameController.text = "${widget.firstName} ${widget.lastName}";
      titleController.text =
          widget.activityData.title ??
          "${widget.activityData.activityType}, ${(widget.activityData.totalDistance! / 1000).toString()}";
      descriptionController.text = widget.activityData.description ?? "";
      activityController.text = widget.activityData.activityType ?? "Unknown";
      _visibility = widget.activityData.visibility;
    });
  }

  /// Get text for save button
  String getSaveButtonText() {
    if (widget.editMode) {
      return "Save changes";
    } else if (!widget.editMode && !activitySaved) {
      return "Save activity";
    } else if (!widget.editMode && activitySaved) {
      return "Activity saved";
    }
    return "Unknown";
  }

  /// Get callback function for save button
  VoidCallback? getSaveButtonCallback() {
    if (activitySaved && !widget.editMode) {
      return null; // No action if activity saved after training
    } else if (!activitySaved && !widget.editMode) {
      return handleSaveActivity;
    } else if (widget.editMode) {
      return handleEditActivity;
    }
    return null;
  }

  /// Set last visibility used by user
  Future<void> setLastVisibility() async {
    String? visibilityS = await PreferencesService.loadString(PreferenceNames.lastVisibility);

    if (visibilityS != null && visibilityS.isNotEmpty) {
      if (visibilityS == enums.ComVisibility.me.toString()) {
        setState(() {
          _visibility = enums.ComVisibility.me;
        });
      } else if (visibilityS == enums.ComVisibility.friends.toString()) {
        setState(() {
          _visibility = enums.ComVisibility.friends;
        });
      } else if (visibilityS == enums.ComVisibility.everyone.toString()) {
        setState(() {
          _visibility = enums.ComVisibility.everyone;
        });
      }
    }
  }

  /// Save last visibility to preferences
  Future<void> saveLastVisibility() async {
    PreferencesService.saveString(PreferenceNames.lastVisibility, _visibility.toString());
  }

  /// Init async data
  Future<void> initAsync() async {
    setLastVisibility();
  }

  /// Handle edit activity to database
  Future<void> handleEditActivity() async {
    if (widget.readonly) {
      return;
    }

    Activity userActivity = Activity(
      activityId: widget.activityData.activityId,
      uid: widget.activityData.uid,
      activityType: activityController.text.trim(),
      description: descriptionController.text.trim(),
      title: titleController.text.trim(),
      totalDistance: widget.activityData.totalDistance,
      elapsedTime: widget.activityData.elapsedTime,
      visibility: _visibility,
      startTime: widget.activityData.startTime,
      trackedPath: widget.activityData.trackedPath,
      photos: widget.activityData.photos,
      pace: widget.activityData.pace,
      avgSpeed: widget.activityData.avgSpeed,
      calories: widget.activityData.calories,
      elevationGain: widget.activityData.elevationGain,
      createdAt: widget.activityData.createdAt,
      steps: widget.activityData.steps,
    );

    if (passedActivity.isEqual(userActivity)) {
      if (mounted) {
        AppUtils.showMessage(context, 'No changes to save!');
      }
      return;
    }

    // Save activity to database
    Activity? savedActivity = await ActivityService.saveActivity(userActivity);
    if (savedActivity != null) {
      passedActivity = savedActivity;
      if (mounted) {
        AppUtils.showMessage(context, 'Changes saved successfully!');
      }
    } else {
      if (mounted) {
        AppUtils.showMessage(context, 'Failed to save changes. Please try again.');
      }
    }
  }

  /// Handle saving activity to database
  Future<void> handleSaveActivity() async {
    if (widget.readonly) {
      return;
    }

    // Activity data
    Activity userActivity = Activity(
      activityId: "",
      uid: widget.activityData.uid,
      activityType: activityController.text.trim(),
      description: descriptionController.text.trim(),
      title: titleController.text.trim(),
      totalDistance: widget.activityData.totalDistance,
      elapsedTime: widget.activityData.elapsedTime,
      visibility: _visibility,
      startTime: widget.activityData.startTime,
      trackedPath: widget.activityData.trackedPath,
      pace: widget.activityData.pace,
      avgSpeed: widget.activityData.avgSpeed,
      calories: widget.activityData.calories,
      elevationGain: widget.activityData.elevationGain,
      createdAt: widget.activityData.createdAt,
      steps: widget.activityData.steps,
      competitionId: widget.currentUserCompetition?.competitionId ?? '',
    );

    // Save activity to database
    Activity? savedActivity = await ActivityService.saveActivity(userActivity);

    if (savedActivity != null) {
      // Save competition result
      final userResult = ResultRecord(
        recordId: "",
        userUid: AppData.instance.currentUser!.uid,
        firstName: AppData.instance.currentUser!.firstName,
        lastName: AppData.instance.currentUser!.lastName,
        distance: widget.activityData.totalDistance ?? 0.0,
        finished: widget.activityData.totalDistance! >= widget.currentUserCompetition!.distanceToGo,
        time: Duration(seconds: widget.activityData.elapsedTime!),
        activityId: savedActivity.activityId,
      );

      if (widget.currentUserCompetition != null) {
        CompetitionService.addOrUpdateRecord(
          widget.currentUserCompetition!.competitionId,
          userResult,
        );
      }
      // Clear all fields from track state
      TrackState.trackStateInstance.clearAllFields(notify: true);
      saveLastVisibility();
      if (mounted) {
        AppUtils.showMessage(
          context,
          'Activity saved successfully!',
          messageType: MessageType.success,
        );
      }

      /// Save last visibility to local prefs
      setState(() {
        activitySaved = true;
      });
    } else {
      if (mounted) {
        AppUtils.showMessage(context, 'Failed to save activity. Please try again.');
      }
    }
  }

  void leavePageEdit(BuildContext context) {
    Activity userActivity = Activity(
      activityId: widget.activityData.activityId,
      uid: widget.activityData.uid,
      activityType: activityController.text.trim(),
      description: descriptionController.text.trim(),
      title: titleController.text.trim(),
      totalDistance: widget.activityData.totalDistance,
      elapsedTime: widget.activityData.elapsedTime,
      visibility: _visibility,
      startTime: widget.activityData.startTime,
      trackedPath: widget.activityData.trackedPath,
      photos: widget.activityData.photos,
      pace: widget.activityData.pace,
      avgSpeed: widget.activityData.avgSpeed,
      calories: widget.activityData.calories,
      elevationGain: widget.activityData.elevationGain,
      createdAt: widget.activityData.createdAt,
      steps: widget.activityData.steps,
    );

    // If there is no changes, just pop
    if (passedActivity.isEqual(userActivity)) {
      Navigator.of(context).pop();
      return;
    }

    AppAlertDialog alert = AppAlertDialog(
      titleText: "Warning",
      contentText:
          "You have unsaved changes\n\n"
          "If you leave now, your changes will be lost.\n\n"
          "Are you sure you want to leave?",
      textLeft: "Cancel",
      textRight: "Yes",
      colorBackgroundButtonRight: AppColors.danger,
      colorButtonForegroundRight: AppColors.white,
      onPressedLeft: () {
        Navigator.of(context).pop();
      },
      onPressedRight: () {
        Navigator.of(context).pop(); // Two times to close dialog and screen
        Navigator.of(context).pop();
      },
    );

    showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by outside tap
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// Ask if we are sure if we want to leave a page without saving when saving activity for the first time
  void leavePage(BuildContext context) {
    AppAlertDialog alert = AppAlertDialog(
      titleText: "Warning",
      contentText:
          "You haven't saved this activity yet.\n\n"
          "If you leave now, your activity will be lost.\n\n"
          "Are you sure you want to leave?",
      textLeft: "Cancel",
      textRight: "Yes",
      colorBackgroundButtonRight: AppColors.danger,
      colorButtonForegroundRight: AppColors.white,
      onPressedLeft: () {
        Navigator.of(context).pop();
      },
      onPressedRight: () {
        TrackState.trackStateInstance.clearAllFields(
          notify: true,
        ); // Clear all fields from track state
        Navigator.of(context).pop(); // Two times to close dialog and screen
        Navigator.of(context).pop();
      },
    );

    showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by outside tap
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void onTapMap(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.trackedPathMap, arguments: {'activity': widget.activityData});
  }

  /// Method invoked when user wants to select change activity
  void onTapActivity() async {
    final selectedActivity = await Navigator.pushNamed(
      context,
      AppRoutes.activityChoose,
      arguments: {'currentActivity': activityController.text.trim()},
    );
    if (selectedActivity != null && selectedActivity is String && selectedActivity.isNotEmpty) {
      setState(() {
        activityController.text = selectedActivity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, String? result) async {
        if (!didPop) {
          if (!widget.readonly && !activitySaved && !widget.editMode) {
            leavePage(context);
          } else if (widget.editMode) {
            leavePageEdit(context);
          } else {
            Navigator.pop(context, null);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(title: Text("Activity summary")),
        body: PageContainer(
          assetPath: AppImages.appBg5,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: AppUiConstants.verticalSpacingButtons),
                if (widget.currentUserCompetition != null) ...[
                  CompetitionFinishBanner(
                    competition: widget.currentUserCompetition!,
                    activity: widget.activityData,
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                ],
                // First name and last name
                TextFormField(
                  controller: fullNameController,
                  textAlign: TextAlign.left,
                  readOnly: true,
                  enabled: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(20),
                    border: AppUiConstants.borderTextFields,
                    label: Text("Full name"),
                    labelStyle: AppUiConstants.labelStyleTextFields,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(AppImages.defaultProfilePhoto),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                // Title
                TextFormField(
                  readOnly: widget.readonly,
                  controller: titleController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                // Description
                Visibility(
                  visible:
                      !(widget.readonly && (widget.activityData.description?.isEmpty ?? false)),
                  child: TextField(
                    readOnly: widget.readonly,
                    maxLines: 3,
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Description"),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                // Activity type
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.left,
                        controller: activityController,
                        decoration: InputDecoration(
                          labelText: "Activity type",
                          suffixIcon: IconButton(
                            onPressed: widget.readonly ? null : () => onTapActivity(),
                            icon: Icon(Icons.list, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppUiConstants.horizontalSpacingTextFields),

                    // Visibility
                    Expanded(
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(iconTheme: IconThemeData(color: Colors.white)),
                        child: IgnorePointer(
                          ignoring: widget.readonly,
                          child: DropdownMenu(
                            initialSelection: _visibility,
                            label: Text("Visibility", style: TextStyle(color: Colors.white)),
                            textStyle: TextStyle(color: Colors.white),
                            width: double.infinity,
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(AppColors.primary),
                            ),
                            inputDecorationTheme: InputDecorationTheme(
                              labelStyle: TextStyle(color: Colors.white),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              ),
                            ),
                            textAlign: TextAlign.left,
                            // Selecting visibility
                            onSelected: (enums.ComVisibility? visibility) {
                              setState(() {
                                if (visibility != null) {
                                  _visibility = visibility;
                                }
                              });
                            },
                            // Icon
                            trailingIcon: Icon(color: Colors.white, Icons.arrow_drop_down),
                            selectedTrailingIcon: Icon(color: Colors.white, Icons.arrow_drop_up),
                            dropdownMenuEntries: <DropdownMenuEntry<enums.ComVisibility>>[
                              DropdownMenuEntry(
                                value: enums.ComVisibility.me,
                                label: "Only Me",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: enums.ComVisibility.friends,
                                label: "Friends",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: enums.ComVisibility.everyone,
                                label: "Everyone",
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(AppColors.primary),
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                ),
                              ),
                            ],
                          ),
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
                        if (widget.activityData.elapsedTime != null)
                          StatCard(
                            title: "Time",
                            value: ActivityService.formatElapsedTimeFromSeconds(
                              widget.activityData.elapsedTime!,
                            ),
                            icon: Icon(Icons.timer),
                          ),
                        if (widget.activityData.totalDistance != null)
                          StatCard(
                            title: "Distance",
                            value:
                                '${(widget.activityData.totalDistance! / 1000).toStringAsFixed(2)} km',
                            icon: Icon(Icons.social_distance),
                          ),
                        if (widget.activityData.pace != null)
                          StatCard(
                            title: "Pace",
                            value: AppUtils.formatPace(widget.activityData.pace!),
                            icon: Icon(Icons.man),
                          ),
                        if (widget.activityData.calories != null)
                          StatCard(
                            title: "Calories",
                            value: '${widget.activityData.calories?.toStringAsFixed(0)} kcal',
                            icon: Icon(Icons.local_fire_department),
                          ),
                        if (widget.activityData.avgSpeed != null)
                          StatCard(
                            title: "Avg Speed",
                            value: '${widget.activityData.avgSpeed?.toStringAsFixed(1)} km/h',
                            icon: Icon(Icons.speed),
                          ),
                        if (widget.activityData.steps != null)
                          StatCard(
                            title: "Steps",
                            value: widget.activityData.steps.toString(),
                            icon: Icon(Icons.directions_walk),
                          ),
                        if (widget.activityData.elevationGain != null)
                          StatCard(
                            title: "Elevation",
                            value: '${widget.activityData.elevationGain?.toStringAsFixed(0)} m',
                            icon: Icon(Icons.terrain),
                          ),
                      ],
                    ),
                  ),
                ),

                // Flutter map if there is a path
                if (widget.activityData.trackedPath?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                widget.activityData.trackedPath?.first ??
                                LatLng(AppConstants.defaultLat, AppConstants.defaultLon),
                            initialZoom: 15.0,
                            onMapReady: () async {
                              // Delay to load a tiles properly
                              Future.delayed(const Duration(milliseconds: 100), () {
                                AppUtils.fitMapToPath(
                                  widget.activityData.trackedPath ?? [],
                                  _mapController,
                                );
                              });
                            },
                            interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                            onTap: (tapPosition, point) => {onTapMap(context)},
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                if (widget.activityData.trackedPath != null &&
                                    widget.activityData.trackedPath!.length > 1)
                                  Marker(
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
                if (!widget.readonly && !activitySaved)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: getSaveButtonText(),
                      onPressed: getSaveButtonCallback(),
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
