import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/enums/competition_goal.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/constans/app_routes.dart';
import 'package:run_track/features/competitions/pages/meeting_place.dart';
import 'package:run_track/common/pages/users_list.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/user_service.dart';

import '../../../common/enums/enter_context.dart';
import '../../../common/enums/visibility.dart' as enums;
import '../../../common/utils/utils.dart';
import '../../../services/competition_service.dart';
import '../../../services/preferences_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/preference_names.dart';
import '../../../theme/ui_constants.dart';
import 'package:flutter/services.dart';
import '../../../common/enums/competition_role.dart';
import 'package:geocoding/geocoding.dart';

class CompetitionDetails extends StatefulWidget {
  final CompetitionContext enterContext;
  final Competition? competitionData;
  final int initTab; // Tab index to set a start visibility

  const CompetitionDetails({super.key, required this.enterContext, this.competitionData, required this.initTab});

  @override
  State<CompetitionDetails> createState() {
    return _AddCompetition();
  }
}

class _AddCompetition extends State<CompetitionDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _registrationDeadline = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityHours = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityMinutes = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _meetingPlaceController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _goalTypeController = TextEditingController();
  bool competitionAdded = false;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  CompetitionGoal _competitionGoal = CompetitionGoal.distance;
  bool canPause = true;
  bool edit = true; // Can we edit a competition?
  Competition? competition;
  bool readOnly = false;
  bool acceptedInvitation = false; // If users is invited and enter context is context invited users can accept invitation or not
  bool declined = false; // If users is invited and enter context is context invited users can decline invitation

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _registrationDeadline.dispose();
    _maxTimeToCompleteActivityHours.dispose();
    _maxTimeToCompleteActivityMinutes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.startPage, (route) => false);
      return;
    }

    // Set visibility based on init tab
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      if (widget.initTab == 0) {
        setState(() {
          _visibility = enums.ComVisibility.me;
        });
      } else if (widget.initTab == 1) {
        setState(() {
          _visibility = enums.ComVisibility.friends;
        });
      } else if (widget.initTab == 2) {
        setState(() {
          _visibility = enums.ComVisibility.everyone;
        });
      }
    }

    if (widget.enterContext != CompetitionContext.ownerModify) {  // Make fields readonly for
      setState(() {
        readOnly = true;
      });
    }

    // Assign a competition
    competition = widget.competitionData;
    if (competition != null) {
      // Set all fields
      _organizerController.text = _nameController.text = competition!.name;
      _descriptionController.text = competition!.description ?? "";
      _startDateController.text = AppUtils.formatDateTime(competition!.startDate);
      _endDateController.text = AppUtils.formatDateTime(competition!.endDate);
      _registrationDeadline.text = AppUtils.formatDateTime(competition!.registrationDeadline);
      _maxTimeToCompleteActivityHours.text = competition!.maxTimeToCompleteActivityHours.toString();
      _maxTimeToCompleteActivityMinutes.text = competition!.maxTimeToCompleteActivityMinutes.toString();
      _activityController.text = competition!.activityType ?? "";
      _visibility = competition!.visibility;
      _competitionGoal = competition!.competitionGoalType;
      _goalController.text = competition!.goal.toString();

      String? latStr = competition?.location?.latitude.toStringAsFixed(4);
      String? lngStr = competition?.location?.longitude.toStringAsFixed(4);
      if (competition!.locationName != null && competition!.location?.longitude != null && competition!.location?.latitude != null) {
        _meetingPlaceController.text = "${competition?.locationName}\nLat: ${latStr ?? ''}, Lng: ${lngStr ?? ''}";
      } else if (competition!.location?.longitude != null && competition!.location?.latitude != null) {
        _meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
      }
    } else {
      // Create new empty competition
      competition = Competition(
        organizerUid: AppData.currentUser!.uid,
        name: "",
        description: "",
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        visibility: enums.ComVisibility.me,
        competitionGoalType: CompetitionGoal.distance,
        goal: 10,
      );
    }
  }

  Future<void> initializeAsync() async {
    // Set name of user
    if (widget.enterContext == CompetitionContext.ownerCreate || widget.enterContext == CompetitionContext.ownerModify) {
      _organizerController.text = AppData.currentUser?.firstName ?? "";
      _organizerController.text += ' ${AppData.currentUser?.lastName ?? ""}';
    } else if (widget.enterContext == CompetitionContext.participant ||
        widget.enterContext == CompetitionContext.invited ||
        widget.enterContext == CompetitionContext.participant ||
        widget.enterContext == CompetitionContext.viewerAbleToJoin ||
        widget.enterContext == CompetitionContext.viewerNotAbleToJoin) {
      final user = await UserService.fetchUser(competition?.organizerUid ?? "");
      if (user != null) {
        setState(() {
          _organizerController.text = user.firstName;
          _organizerController.text += ' ${user.lastName}';
        });
      }
    }

    await setLastActivityType();
    setState(() {});
  }

  /// Get icon for goal input
  Icon getIconForGoalInput() {
    if (_competitionGoal == CompetitionGoal.distance) {
      return Icon(Icons.directions_run, color: AppColors.white);
    } else if (_competitionGoal == CompetitionGoal.longestDistance) {
      return Icon(Icons.run_circle_rounded, color: AppColors.white);
    } else if (_competitionGoal == CompetitionGoal.timedActivity) {
      return Icon(Icons.timer, color: AppColors.white);
    } else if (_competitionGoal == CompetitionGoal.steps) {
      return Icon(Icons.directions_walk, color: AppColors.white);
    }
    return Icon(Icons.run_circle_outlined);
  }

  /// Get label text for goal input
  String getLabelTextGoal() {
    if (_competitionGoal == CompetitionGoal.distance || _competitionGoal == CompetitionGoal.longestDistance) {
      return "Distance in km";
    } else if (_competitionGoal == CompetitionGoal.steps) {
      return "Steps";
    } else if (_competitionGoal == CompetitionGoal.timedActivity) {
      return "Time in minutes";
    }
    return "Goal";
  }

  /// Set last competition used in adding
  Future<void> setLastActivityType() async {
    String? lastCompetition = await PreferencesService.loadString(PreferenceNames.lastUsedPreferenceAddCompetition);

    if (lastCompetition != null && lastCompetition.isNotEmpty) {
      if (AppData.currentUser?.activityNames!.contains(lastCompetition) ?? false) {
        _activityController.text = lastCompetition;
        return;
      }
      _activityController.text = AppData.currentUser?.activityNames?.first ?? "Unknown";
    }
  }

  /// Leave page if changes are done
  void leavePageEdit(BuildContext context) {
    if (widget.enterContext != CompetitionContext.ownerModify) {
      // If it is not owner and he is not modifying competition, leave
      Navigator.of(context).pop();
      return;
    }

    var compData = Competition(
      competitionId: competition?.competitionId ?? "",
      organizerUid: widget.competitionData?.organizerUid ?? AppData.currentUser!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      visibility: _visibility,
      startDate: DateTime.parse(_startDateController.text.trim()),
      endDate: DateTime.parse(_endDateController.text.trim()),
      registrationDeadline: DateTime.parse(_registrationDeadline.text.trim()),
      maxTimeToCompleteActivityHours: int.tryParse(_maxTimeToCompleteActivityHours.text.trim()),
      maxTimeToCompleteActivityMinutes: int.tryParse(_maxTimeToCompleteActivityMinutes.text.trim()),
      activityType: _activityController.text.trim(),
      invitedParticipantsUid: competition?.invitedParticipantsUid ?? [],
      participantsUid: competition?.participantsUid ?? [],
      competitionGoalType: _competitionGoal,
      location: competition?.location,
      locationName: competition?.locationName,
      goal: _goalController.text.trim().isNotEmpty ? double.parse(_goalController.text.trim()) : 0,
      createdAt: DateTime.now(),
      photos: [],
      closedBeforeEndTime: competition?.closedBeforeEndTime ?? false,
    );

    // If there is no changes, just pop
    if (widget.competitionData == null || CompetitionService.competitionsEqual(widget.competitionData!, compData)) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Warning", textAlign: TextAlign.center),
          content: const Text(
            "You have unsaved changes\n\n"
            "If you leave now, your changes will be lost.\n\n"
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

  /// On tap/ on pressed functions

  void onTapActivityType() async {
    final selectedActivity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivityChoose(currentActivity: _activityController.text.trim())),
    );

    // If the user selected something, update the TextField
    if (selectedActivity != null && selectedActivity.isNotEmpty) {
      _activityController.text = selectedActivity;
      AppData.lastActivityString = selectedActivity;
      // Save it to local preferences
      PreferencesService.saveString(PreferenceNames.lastUsedPreferenceAddCompetition, selectedActivity);
    }
  }

  /// On pressed list participants
  void onPressedListParticipants(BuildContext context) async {
    EnterContextUsersList enterContext = EnterContextUsersList.participantsModify;
    if(widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) {
      enterContext = EnterContextUsersList.participantsReadOnly;
    }


    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsersList(
          usersUid: competition?.participantsUid ?? [],
          usersUid2: competition?.invitedParticipantsUid ?? [],
          enterContext: enterContext,
        ),
      ),
    );
    if (result != null) {
      // Set invited participants
      setState(() {
        competition?.invitedParticipantsUid = result;
      });
    }
  }

  /// Add place where runners can meet
  Future<void> onTapAddMeetingPlace() async {
    LatLng? latLng;
    final location = competition?.location;

    if (location?.latitude != null && location?.longitude != null) {
      latLng = LatLng(location!.latitude, location.longitude);
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => MeetingPlaceMap(latLng: latLng)));

    if (result != null) {
      competition?.location = result;
      String? latStr = competition?.location?.latitude.toStringAsFixed(4);
      String? lngStr = competition?.location?.longitude.toStringAsFixed(4);

      final placeNames = await placemarkFromCoordinates(result.latitude, result.longitude);

      if (placeNames.isNotEmpty) {
        final place = placeNames.first;
        competition?.locationName = "${place.locality ?? ''}, ${place.thoroughfare ?? ''}".trim();

        setState(() {
          _meetingPlaceController.text = "${competition?.locationName}\nLat: ${latStr ?? ''}, Lng: ${lngStr ?? ''}";
        });
      } else {
        _meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
      }
    }
  }

  // Validators
  // Name of competition
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name';
    }
    if (value.trim().length < 5) {
      return 'Name must be at least 5 characters';
    }
    return null;
  }

  // Description
  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a description';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  // Activity type
  String? validateActivity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select an activity';
    }
    return null;
  }

  // Start date
  String? validateStartDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please pick a start date of competition';
    }
    if (DateTime.tryParse(value.trim()) == null) {
      return 'Invalid start date';
    }
    if (DateTime.now().isAfter(DateTime.parse(value.trim()))) {
      return 'Start date must be in the future';
    }

    return null;
  }

  // End date
  String? validateEndDate(String? value, String? startDateValue) {
    if (value == null || value.trim().isEmpty) {
      return 'Please pick an end date';
    }
    DateTime? start = DateTime.tryParse(startDateValue ?? '');
    DateTime? end = DateTime.tryParse(value.trim());
    if (end == null) {
      return 'Invalid end date';
    }
    if (start == null) {
      return 'Invalid start date';
    }
    if (end.isBefore(start)) {
      return 'End date must be after start date';
    }
    if (start.add(Duration(hours: 2)).isAfter(end)) {
      return 'Competition cannot be shorter that 2 hours';
    }

    return null;
  }

  // Registration deadline
  String? validateRegistrationDeadline(String? startDateValue, String? endDateValue, String? value) {
    if (startDateValue == null || startDateValue.trim().isEmpty) {
      return 'Please select a start date before registration deadline';
    }
    if (endDateValue == null || endDateValue.trim().isEmpty) {
      return 'Please select an end date before registration deadline';
    }
    DateTime? start = DateTime.tryParse(startDateValue);
    DateTime? end = DateTime.tryParse(endDateValue);
    if (start == null) {
      return 'Invalid end date';
    }
    if (end == null) {
      return 'Invalid end date';
    }

    if (value == null || value.trim().isEmpty) {
      return 'Please pick a registration deadline';
    }
    DateTime? registrationDeadline = DateTime.tryParse(value.trim());
    if (registrationDeadline == null) {
      return 'Invalid date';
    }
    if (start.isBefore(registrationDeadline)) {
      return 'Registration deadline must be before start date';
    }
    if (end.isBefore(registrationDeadline)) {
      return 'Registration deadline must be before end date';
    }
    if (DateTime.now().isAfter(registrationDeadline)) {
      return 'Registration deadline must be in the future';
    }
    if (registrationDeadline.isBefore(DateTime.now().add(Duration(hours: 1)))) {
      return 'Registration deadline must be at least 1 hour from now';
    }
    return null;
  }

  // Max time to complete activity hours
  String? validateGoal(String? value) {
    if (_competitionGoal == CompetitionGoal.distance || _competitionGoal == CompetitionGoal.longestDistance) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter distance in km';
      }
      if (int.tryParse(value.trim()) == null) {
        return 'Enter a valid number';
      }

      if (int.tryParse(value.trim())! <= 0) {
        return 'Distance must be positive and greater than 0';
      }
    } else if (_competitionGoal == CompetitionGoal.steps) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter steps';
      }
      if (int.tryParse(value.trim()) == null) {
        return 'Enter a valid number';
      }
      if (int.tryParse(value.trim())! <= 0) {
        return 'Steps must be positive and greater than 0';
      }
    } else if (_competitionGoal == CompetitionGoal.timedActivity) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter time in minutes';
      }
      if (int.tryParse(value.trim()) == null) {
        return 'Enter a valid number';
      }
      if (int.tryParse(value.trim())! <= 0) {
        return 'Time must be positive and greater than 0';
      }
    }

    return null;
  }

  // Max time to complete activity hours
  String? validateHours(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (int.tryParse(value.trim()) == null) {
        return 'Enter a valid number';
      }
      if (int.tryParse(value.trim()) == 0) {
        return 'There must be at least one hour to complete activity';
      }
    }

    return null;
  }

  // Max time to complete activity minutes
  String? validateMinutes(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (int.tryParse(value.trim()) == null) {
        return 'Enter a valid number';
      }
      int minutes = int.parse(value.trim());
      if (minutes < 0 || minutes > 59) {
        return 'Minutes must be between 0 and 59';
      }
    }

    return null;
  }

  /// Close competition
  void closeCompetition() async {
    bool res = await CompetitionService.closeCompetitionBeforeEndTime(competition!.competitionId);
    if (res) {
      if (mounted) {
        AppUtils.showMessage(context, "Competition closed successfully");
      }
    } else {
      if (mounted) {
        AppUtils.showMessage(context, "Error closing competition");
      }
    }
  }

  /// Delete  competition
  void deleteCompetition(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.alertDialogColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
          alignment: Alignment.center,
          title: const Text("Warning", textAlign: TextAlign.center),
          content: const Text(
            "Are you sure you want to delete this activity?\n\n"
            "This action cannot be undone.",
            textAlign: TextAlign.center,
          ),

          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor:AppColors.gray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                SizedBox(width: AppUiConstants.horizontalSpacingButtons),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor:AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                      ),
                    ),
                    onPressed: () async {
                      bool res = await CompetitionService.deleteCompetition(widget.competitionData!.competitionId);

                      if (res) {
                          AppUtils.showMessage(context, "Competition deleted successfully");
                      }
                      if (!res) {
                          AppUtils.showMessage(context, "Error deleting competition");
                      }
                      if (mounted) {
                        Navigator.of(context).pop(); // Two times to close dialog and screen
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Yes"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Accept invitation
  void acceptInvitation() async {
    if (widget.competitionData != null) {
      bool res = await CompetitionService.acceptInvitation(widget.competitionData!);

      if (res) {
        if (mounted) {
          acceptedInvitation = true; // Users accepts invitation
        }
      } else {
        if (mounted) {
          AppUtils.showMessage(context, "Error accepting invitation");
        }
      }
    }
  }

  /// Accept invitation
  void declineInvitation() async {
    if (widget.competitionData != null) {
      bool res = await CompetitionService.declineInvitation(widget.competitionData!);

      if (res) {
        if (mounted) {
          declined = true; // Users declines invitation
        }
      } else {
        if (mounted) {
          AppUtils.showMessage(context, "Error declining invitation");
        }
      }
    }
  }

  /// Save competition to database
  void handleSaveCompetition() async {
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    var compData = Competition(
      competitionId: "",
      organizerUid: AppData.currentUser!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      visibility: _visibility,
      startDate: DateTime.parse(_startDateController.text.trim()),
      endDate: DateTime.parse(_endDateController.text.trim()),
      registrationDeadline: DateTime.parse(_registrationDeadline.text.trim()),
      maxTimeToCompleteActivityHours: int.tryParse(_maxTimeToCompleteActivityHours.text.trim()),
      maxTimeToCompleteActivityMinutes: int.tryParse(_maxTimeToCompleteActivityMinutes.text.trim()),
      activityType: _activityController.text.trim(),
      invitedParticipantsUid: competition?.invitedParticipantsUid ?? [],
      participantsUid: competition?.participantsUid ?? [],
      competitionGoalType: _competitionGoal,
      location: competition?.location,
      locationName: competition?.locationName,
      goal: _goalController.text.trim().isNotEmpty ? double.parse(_goalController.text.trim()) : 0,
      createdAt: DateTime.now(),
      photos: [],
    );

    bool result = await CompetitionService.saveCompetition(compData);

    if (result) {
      if (widget.enterContext == CompetitionContext.ownerCreate) {
        if (mounted) {
          AppUtils.showMessage(context, "Competition saved successfully");
        }
        competitionAdded = true;
      } else if (widget.enterContext == CompetitionContext.ownerModify) {
        if (mounted) {
          AppUtils.showMessage(context, "Changes saved successfully");
        }
        competitionAdded = true;
      }
    } else {
      if (mounted) {
        AppUtils.showMessage(context, "Error saving competition");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "Add competition",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,

        actions: [
          if (widget.enterContext == CompetitionContext.ownerModify)
            IconButton(onPressed: () => deleteCompetition(context), icon: Icon(Icons.delete,color: Colors.white)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/appBg6.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Organizer
                  TextField(
                    controller: _organizerController,
                    textAlign: TextAlign.left,
                    readOnly: true,
                    enabled: false,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(20),
                      border: AppUiConstants.borderTextFields,
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                      label: Text("Organizer"),
                      labelStyle: AppUiConstants.labelStyleTextFields,
                      filled: true,
                      fillColor: AppColors.textFieldsBackground,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: (AppData.currentUser?.profilePhotoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(AppData.currentUser!.profilePhotoUrl!)
                              : AssetImage('assets/DefaultProfilePhoto.png'),
                        ),
                      ),
                      prefixStyle: TextStyle(),
                    ),
                  ),

                  // Name of competition
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  TextFormField(
                    controller: _nameController,
                    style: AppUiConstants.textStyleTextFields,
                    readOnly: readOnly,
                    decoration: InputDecoration(
                      hintText: "Name of competition",
                      hintStyle: TextStyle(color: AppColors.textFieldsHints),
                      border: AppUiConstants.borderTextFields,
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                      label: Text("Name of competition"),
                      labelStyle: AppUiConstants.labelStyleTextFields,
                      filled: true,
                      fillColor: AppColors.textFieldsBackground,
                    ),
                    validator: validateName,
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Description
                  TextFormField(
                    readOnly: readOnly,
                    maxLines: 3,
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: "Describe your competition",
                      hintStyle: TextStyle(color: AppColors.textFieldsHints),
                      border: AppUiConstants.borderTextFields,
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                      label: Text("Description"),
                      labelStyle: AppUiConstants.labelStyleTextFields,
                      filled: true,
                      fillColor: AppColors.textFieldsBackground,
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: validateDescription,
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Activity type of competition
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _activityController,
                          style: AppUiConstants.textStyleTextFields,
                          textAlign: TextAlign.left,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Activity type",
                            labelStyle: AppUiConstants.labelStyleTextFields,
                            enabledBorder: AppUiConstants.enabledBorderTextFields,
                            focusedBorder: AppUiConstants.focusedBorderTextFields,
                            errorBorder: AppUiConstants.errorBorderTextFields,
                            focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                            filled: true,
                            fillColor: AppColors.textFieldsBackground,
                            suffixIcon: Padding(
                              padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
                              child: IconButton(
                                onPressed: readOnly ? null : () => onTapActivityType(),
                                icon: Icon(Icons.list, color: Colors.white),
                              ),
                            ),
                          ),
                          validator: validateActivity,
                        ),
                      ),
                      SizedBox(width: AppUiConstants.horizontalSpacingTextFields),
                      // Visibility
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(iconTheme: IconThemeData(color: Colors.white)),
                          child: DropdownMenu(
                            enabled: !readOnly,
                            maxLines: 1,
                            width: double.infinity,
                            textAlign: TextAlign.left,
                            textStyle: AppUiConstants.textStyleTextFields,
                            label: Text("Visibility"),
                            initialSelection: _visibility,
                            inputDecorationTheme: InputDecorationTheme(
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              filled: true,
                              fillColor: AppColors.textFieldsBackground,
                            ),
                            onSelected: (enums.ComVisibility? visibility) {
                              // Selecting visibility
                              setState(() {
                                if (visibility != null) {
                                  _visibility = visibility;
                                }
                              });
                            },
                            trailingIcon: Icon(color: Colors.white, Icons.arrow_drop_down),
                            selectedTrailingIcon: Icon(color: Colors.white, Icons.arrow_drop_up),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.6)),
                              alignment: Alignment.center,
                            ),
                            dropdownMenuEntries: <DropdownMenuEntry<enums.ComVisibility>>[
                              DropdownMenuEntry(
                                value: enums.ComVisibility.me,
                                label: "Only Me",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: enums.ComVisibility.friends,
                                label: "Friends",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: enums.ComVisibility.everyone,
                                label: "Everyone",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Start date
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: readOnly,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Start date",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        enabledBorder: AppUiConstants.enabledBorderTextFields,
                        focusedBorder: AppUiConstants.focusedBorderTextFields,
                        errorBorder: AppUiConstants.errorBorderTextFields,
                        focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                        filled: true,
                        fillColor: AppColors.textFieldsBackground,
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      validator: validateStartDate,
                      onTap: () async {
                        if (readOnly) {
                          return;
                        }
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _startDateController,false);
                      },
                    ),
                  ),
                  // End date
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      style: AppUiConstants.textStyleTextFields,
                      decoration: InputDecoration(
                        labelText: "End date",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        enabledBorder: AppUiConstants.enabledBorderTextFields,
                        focusedBorder: AppUiConstants.focusedBorderTextFields,
                        errorBorder: AppUiConstants.errorBorderTextFields,
                        focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                        filled: true,
                        fillColor: AppColors.textFieldsBackground,
                        prefixIcon: Icon(Icons.calendar_month, color: Colors.white),
                      ),
                      validator: (value) => validateEndDate(value, _startDateController.text.trim()),
                      onTap: () async {
                        if (readOnly) {
                          return;
                        }
                        AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _endDateController,false);
                      },
                    ),
                  ),

                  // Registration deadline
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _registrationDeadline,
                      readOnly: readOnly,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                        labelText: "Register to",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        enabledBorder: AppUiConstants.enabledBorderTextFields,
                        focusedBorder: AppUiConstants.focusedBorderTextFields,
                        errorBorder: AppUiConstants.errorBorderTextFields,
                        focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                        filled: true,
                        fillColor: AppColors.textFieldsBackground,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                          validateRegistrationDeadline(_startDateController.text.trim(), _endDateController.text.trim(), value),
                      onTap: () async {
                        if (readOnly) {
                          return;
                        }
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _registrationDeadline,false);
                      },
                    ),
                  ),

                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                  Row(
                    children: [
                      // Competition goal
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(iconTheme: IconThemeData(color: Colors.white)),
                          child: DropdownMenu(
                            enabled: !readOnly,
                            maxLines: 1,
                            width: double.infinity,
                            textAlign: TextAlign.left,
                            textStyle: AppUiConstants.textStyleTextFields,
                            label: Text("Competition goal"),
                            initialSelection: _competitionGoal,
                            inputDecorationTheme: InputDecorationTheme(
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              filled: true,
                              fillColor: AppColors.textFieldsBackground,
                            ),
                            onSelected: (value) => {
                              // Selecting visibility
                              setState(() {
                                if (value != null) {
                                  _competitionGoal = value;
                                }
                              }),
                            },
                            trailingIcon: Icon(color: Colors.white, Icons.arrow_drop_down),
                            selectedTrailingIcon: Icon(color: Colors.white, Icons.arrow_drop_up),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.6)),
                              alignment: Alignment.center,
                            ),
                            dropdownMenuEntries: <DropdownMenuEntry<CompetitionGoal>>[
                              DropdownMenuEntry(
                                value: CompetitionGoal.distance,
                                label: "Distance in fastest time",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: CompetitionGoal.longestDistance,
                                label: "Longest distance in fastest time",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: CompetitionGoal.timedActivity,
                                label: "Time goal",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                              DropdownMenuEntry(
                                value: CompetitionGoal.timedActivity,
                                label: "Steps",
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: AppUiConstants.horizontalSpacingTextFields),
                      // Goal of competition
                      Expanded(
                        child: TextFormField(
                          readOnly: readOnly,
                          controller: _goalController,
                          style: AppUiConstants.textStyleTextFields,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: getLabelTextGoal(),
                            labelStyle: AppUiConstants.labelStyleTextFields,
                            enabledBorder: AppUiConstants.enabledBorderTextFields,
                            focusedBorder: AppUiConstants.focusedBorderTextFields,
                            errorBorder: AppUiConstants.errorBorderTextFields,
                            focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                            filled: true,
                            fillColor: AppColors.textFieldsBackground,
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
                              child: IconButton(onPressed: () => onTapActivityType(), icon: getIconForGoalInput()),
                            ),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: validateGoal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Hours to complete activity
                  Column(
                    children: [
                      // Label for hours and minutes
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("Max time to complete activity", style: AppUiConstants.labelStyleTextFields),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxTimeToCompleteActivityHours,
                              readOnly: readOnly,
                              style: AppUiConstants.textStyleTextFields,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                                labelText: "Hours",
                                labelStyle: AppUiConstants.labelStyleTextFields,
                                enabledBorder: AppUiConstants.enabledBorderTextFields,
                                focusedBorder: AppUiConstants.focusedBorderTextFields,
                                errorBorder: AppUiConstants.errorBorderTextFields,
                                focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                                filled: true,
                                fillColor: AppColors.textFieldsBackground,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: validateHours,
                            ),
                          ),
                          SizedBox(width: AppUiConstants.verticalSpacingTextFields),
                          // Minutes to complete activity
                          Expanded(
                            child: TextFormField(
                              controller: _maxTimeToCompleteActivityMinutes,
                              readOnly: readOnly,
                              style: AppUiConstants.textStyleTextFields,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                                labelText: "Minutes",
                                labelStyle: AppUiConstants.labelStyleTextFields,
                                enabledBorder: AppUiConstants.enabledBorderTextFields,
                                focusedBorder: AppUiConstants.focusedBorderTextFields,
                                errorBorder: AppUiConstants.errorBorderTextFields,
                                focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                                filled: true,
                                fillColor: AppColors.textFieldsBackground,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: validateMinutes,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Meeting place
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _meetingPlaceController,
                      readOnly: true,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.add_location_alt, color: Colors.white),
                        labelText: "Meeting place",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        enabledBorder: AppUiConstants.enabledBorderTextFields,
                        focusedBorder: AppUiConstants.focusedBorderTextFields,
                        errorBorder: AppUiConstants.errorBorderTextFields,
                        focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                        filled: true,
                        fillColor: AppColors.textFieldsBackground,
                      ),
                      onTap: () async {
                        onTapAddMeetingPlace();
                      },
                    ),
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  // Invited competitors
                  SizedBox(
                    height: 40,
                    child: CustomButton(
                      text: "Participants (${competition?.invitedParticipantsUid.length ?? 0})",
                      onPressed: () => onPressedListParticipants(context),
                    ),
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  if (widget.enterContext == CompetitionContext.ownerCreate)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: competitionAdded ? "Competition added" : "Add competition",
                        onPressed: competitionAdded ? null : () => handleSaveCompetition(),
                      ),
                    ),
                  if (widget.enterContext == CompetitionContext.ownerModify && (competition?.startDate?.isAfter(DateTime.now()) ?? false))
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(text: "Save changes", onPressed: () => handleSaveCompetition()),
                    ),
                  if (widget.enterContext == CompetitionContext.ownerModify && (competition?.startDate?.isBefore(DateTime.now())  ?? false)) ...[
                    SizedBox(height: AppUiConstants.verticalSpacingButtons,),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(text: "Close competition",
                          backgroundColor: AppColors.gray,
                          onPressed: () => closeCompetition()),
                    ),
                  ],
                  if (widget.enterContext == CompetitionContext.invited && declined == false && acceptedInvitation == false)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(text: "Accept invitation", onPressed: () => closeCompetition()),
                    ),
                  if (widget.enterContext == CompetitionContext.invited && declined == false && acceptedInvitation == false)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(text: "Decline invitation", onPressed: () => closeCompetition()),
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
