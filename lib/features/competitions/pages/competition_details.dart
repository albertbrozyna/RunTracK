import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/alert_dialog.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/config/assets/app_images.dart';
import 'package:run_track/features/competitions/pages/meeting_place_map.dart';
import 'package:run_track/common/pages/users_list.dart';
import 'package:run_track/features/competitions/widgets/section.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/user_service.dart';

import '../../../common/enums/enter_context.dart';
import '../../../common/enums/visibility.dart' as enums;
import '../../../common/utils/utils.dart';
import '../../../config/routes/app_routes.dart';
import '../../../services/competition_service.dart';
import '../../../services/preferences_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/preference_names.dart';
import '../../../theme/ui_constants.dart';
import 'package:flutter/services.dart';
import '../../../common/enums/competition_role.dart';
import 'package:geocoding/geocoding.dart';

class CompetitionDetailsPage extends StatefulWidget {
  final CompetitionContext enterContext;
  final Competition? competitionData;
  final int initTab; // Tab index to set a start visibility

  const CompetitionDetailsPage({super.key, required this.enterContext, this.competitionData, required this.initTab});

  @override
  State<CompetitionDetailsPage> createState() => _CompetitionDetailsPageState();
}

class _CompetitionDetailsPageState extends State<CompetitionDetailsPage> {
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

  Competition? competition;

  bool competitionAdded = false;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  bool canPause = true;
  bool edit = true; // Can we edit a competition?
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
    UserService.checkAppUseState(context);
    _setReadOnlyState();
    _setupCompetitionData();
  }

  void _setReadOnlyState() {
    if (widget.enterContext != CompetitionContext.ownerModify &&
        widget.enterContext != CompetitionContext.ownerCreate) {
      readOnly = true;
    }
  }

  void _setupCompetitionData() {
    competition = widget.competitionData;

    if (competition != null) {
      _populateFormFromData(competition!);
    } else {
      _createNewCompetition();
    }
  }

  /// Sync data to controllers
  void _populateFormFromData(Competition data) {
    _nameController.text = data.name;
    _organizerController.text = data.name;
    _descriptionController.text = data.description ?? "";
    _startDateController.text = AppUtils.formatDateTime(data.startDate);
    _endDateController.text = AppUtils.formatDateTime(data.endDate);
    _registrationDeadline.text = AppUtils.formatDateTime(data.registrationDeadline);
    _maxTimeToCompleteActivityHours.text = data.maxTimeToCompleteActivityHours.toString();
    _maxTimeToCompleteActivityMinutes.text = data.maxTimeToCompleteActivityMinutes.toString();
    _activityController.text = data.activityType ?? "";
    _visibility = data.visibility;
    _goalController.text = data.goal.toString();
    _setMeetingPlaceText(data.location, data.locationName);
  }

  Competition _getDataFromForm() {
    final baseCompetition = competition;
    final currentUser = AppData.instance.currentUser;

    return Competition(
      competitionId: baseCompetition?.competitionId ?? "",
      organizerUid: baseCompetition?.organizerUid ?? currentUser?.uid ?? "",
      invitedParticipantsUid: baseCompetition?.invitedParticipantsUid ?? {},
      participantsUid: baseCompetition?.participantsUid ?? {},
      location: baseCompetition?.location,
      locationName: baseCompetition?.locationName,
      closedBeforeEndTime: baseCompetition?.closedBeforeEndTime ?? false,
      photos: baseCompetition?.photos ?? [],
      createdAt: baseCompetition?.createdAt ?? DateTime.now(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      activityType: _activityController.text.trim(),
      visibility: _visibility,

      startDate: DateTime.tryParse(_startDateController.text.trim()) ?? DateTime.now(),
      endDate: DateTime.tryParse(_endDateController.text.trim()) ?? DateTime.now(),
      registrationDeadline: DateTime.tryParse(_registrationDeadline.text.trim()) ?? DateTime.now(),

      goal: double.tryParse(_goalController.text.trim()) ?? 0,

      maxTimeToCompleteActivityHours: int.tryParse(_maxTimeToCompleteActivityHours.text.trim()),
      maxTimeToCompleteActivityMinutes: int.tryParse(_maxTimeToCompleteActivityMinutes.text.trim()),
    );
  }


  void _setMeetingPlaceText(LatLng? location, String? locationName) {
    if (location == null) {
      _meetingPlaceController.text = "";
      return;
    }

    String latStr = location.latitude.toStringAsFixed(4);
    String lngStr = location.longitude.toStringAsFixed(4);

    if (locationName != null && locationName.isNotEmpty) {
      _meetingPlaceController.text = "$locationName\nLat: $latStr, Lng: $lngStr";
    } else {
      _meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
    }
  }

  void _createNewCompetition() {
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      if (widget.initTab == 1) {
        _visibility = enums.ComVisibility.friends;
      } else if (widget.initTab == 2) {
        _visibility = enums.ComVisibility.everyone;
      }
    }

    competition = Competition(
      organizerUid: AppData.instance.currentUser!.uid,
      name: "",
      description: "",
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      visibility: _visibility,
      goal: 10,
      participantsUid: {FirebaseAuth.instance.currentUser!.uid}, // Set owner as fir participant
    );
  }

  Future<void> initializeAsync() async {
    // Set name of user
    if (widget.enterContext == CompetitionContext.ownerCreate || widget.enterContext == CompetitionContext.ownerModify) {
      _organizerController.text = AppData.instance.currentUser?.firstName ?? "";
      _organizerController.text += ' ${AppData.instance.currentUser?.lastName ?? ""}';
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


  /// Set last competition used in adding
  Future<void> setLastActivityType() async {
    String? lastCompetition = await PreferencesService.loadString(PreferenceNames.lastUsedPreferenceAddCompetition);

    if (lastCompetition != null && lastCompetition.isNotEmpty) {
      if (AppData.instance.currentUser?.activityNames!.contains(lastCompetition) ?? false) {
        _activityController.text = lastCompetition;
        return;
      }
      _activityController.text = AppData.instance.currentUser?.activityNames?.first ?? "Unknown";
    }
  }


  /// On tap/ on pressed functions
  void onTapActivityType(BuildContext context) async {
    final selectedActivity = await Navigator.pushNamed(context, AppRoutes.activityChoose);
    if (selectedActivity is String && selectedActivity.isNotEmpty) {
      _activityController.text = selectedActivity;
      AppData.instance.lastActivityString = selectedActivity;

      PreferencesService.saveString(PreferenceNames.lastUsedPreferenceAddCompetition, selectedActivity);
    }
  }

  /// On pressed list participants
  void onPressedListParticipants(BuildContext context) async {
    EnterContextUsersList enterContext = EnterContextUsersList.participantsModify;
    if (widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) {
      enterContext = EnterContextUsersList.participantsReadOnly;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UsersList(
              usersUid: competition?.participantsUid ?? {},
              usersUid2: competition?.invitedParticipantsUid ?? {},
              usersUid3: {},
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

  // Name of competition
  String? validateName(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please enter a name';
    }
    if (value
        .trim()
        .length < 5) {
      return 'Name must be at least 5 characters';
    }
    return null;
  }

  // Description
  String? validateDescription(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please enter a description';
    }
    if (value
        .trim()
        .length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  // Activity type
  String? validateActivity(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please select an activity';
    }
    return null;
  }

  // Start date
  String? validateStartDate(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
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
    if (value == null || value
        .trim()
        .isEmpty) {
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
    if (startDateValue == null || startDateValue
        .trim()
        .isEmpty) {
      return 'Please select a start date before registration deadline';
    }
    if (endDateValue == null || endDateValue
        .trim()
        .isEmpty) {
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

    if (value == null || value
        .trim()
        .isEmpty) {
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
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please enter distance in km';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    if (double.tryParse(value.trim())! <= 0) {
      return 'Distance must be positive and greater than 0';
    }
    return null;
  }

  // Max time to complete activity hours
  String? validateHours(String? value) {
    if (value != null && value
        .trim()
        .isNotEmpty) {
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
    if (value != null && value
        .trim()
        .isNotEmpty) {
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

  //#endregion

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
        return AppAlertDialog(
          titleText: "Warning",
          contentText:
          "Are you sure you want to delete this activity?\n\n"
              "This action cannot be undone.",
          textRight: "Yes",
          textLeft: "Cancel",
          colorBackgroundButtonRight: AppColors.danger,
          colorButtonForegroundRight: AppColors.white,
          onPressedRight: () async {
            bool res = await CompetitionService.deleteCompetition(widget.competitionData!.competitionId);

            if (res) {
              AppUtils.showMessage(context, "Competition deleted successfully");
            }
            if (!res) {
              AppUtils.showMessage(context, "Error deleting competition");
            }
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Two times to close dialog and screen
            }
          },
          onPressedLeft: () {
            Navigator.of(context).pop();
          },
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    var compData = _getDataFromForm();
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

  /// Leave page if changes are done
  void leavePageEdit(BuildContext context) {
    if (widget.enterContext != CompetitionContext.ownerModify) {
      // If it is not owner and he is not modifying competition, leave
      Navigator.of(context).pop();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    var compData = _getDataFromForm();

    // If there is no changes, just pop
    if (widget.competitionData == null || (widget.competitionData?.isEqual(compData) ?? false)) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AppAlertDialog(
          titleText: "Warning",
          contentText:
          "You have unsaved changes\n\n"
              "If you leave now, your changes will be lost.\n\n"
              "Are you sure you want to leave?",
          textLeft: "Cancel",
          textRight: "Yes",
          onPressedLeft: () {
            Navigator.of(context).pop();
          },
          onPressedRight: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }, // Close builder
    ); // Close showDialog
  }

  void _startCompetition() {

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add competition"),
        actions: [
          if (widget.enterContext == CompetitionContext.ownerModify)
            IconButton(
              onPressed: () => deleteCompetition(context),
              icon: Icon(Icons.delete, color: Colors.white),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: PageContainer(
          assetPath: AppImages.appBg4,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if(competition?.startDate != null && competition?.endDate != null && competition!.startDate!.isBefore(DateTime.now()) &&
                    competition!.endDate!.isBefore(DateTime.now()) &&
                    !(competition?.results?.containsKey(FirebaseAuth.instance.currentUser?.uid) ?? false) &&
                    widget.enterContext != CompetitionContext.ownerCreate)...[

                  SizedBox(
                    height: AppUiConstants.verticalSpacingButtons,
                  ),
                  CustomButton(
                      text: competition?.competitionId != AppData.instance.currentCompetition?.competitionId
                          ? "Set as current competition"
                      : "Current competition",
                      onPressed: _startCompetition
                  ), SizedBox(
                    height: AppUiConstants.verticalSpacingButtons,
                  ),
                ],


                Section(
                  title: "Basic info",
                  children: [
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                    // Organizer
                    TextFormField(
                      controller: _organizerController,
                      textAlign: TextAlign.left,
                      readOnly: true,
                      enabled: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(20),
                        border: AppUiConstants.borderTextFields,
                        label: Text("Organizer"),
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: (AppData.instance.currentUser?.profilePhotoUrl?.isNotEmpty ?? false)
                                ? NetworkImage(AppData.instance.currentUser!.profilePhotoUrl!)
                                : AssetImage(AppImages.defaultProfilePhoto),
                          ),
                        ),
                      ),
                    ),


                    // Name of competition
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                    TextFormField(
                      controller: _nameController,
                      style: AppUiConstants.textStyleTextFields,
                      readOnly: readOnly,
                      decoration: InputDecoration(label: Text("Name of competition"), hintText: "Name of competition"),
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
                        label: Text("Description"),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: validateDescription,
                    ),
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                    DropdownMenu(
                      initialSelection: _visibility,
                      enabled: !readOnly,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      label: Text("Visibility"),
                      width: double.infinity,
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
                  ],
                ),

                Section(
                  title: "Competition goal",
                  children: [
                    // Activity type of competition
                    TextFormField(
                      controller: _activityController,
                      style: AppUiConstants.textStyleTextFields,
                      textAlign: TextAlign.left,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Activity type",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        suffixIcon: Padding(
                          padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
                          child: IconButton(
                            onPressed: readOnly ? null : () => onTapActivityType(context),
                            icon: Icon(Icons.list, color: Colors.white),
                          ),
                        ),
                      ),
                      validator: validateActivity,
                    ),
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                    // Competition goal
                    // DropdownMenu(
                    //   enabled: !readOnly,
                    //   maxLines: 1,
                    //   width: double.infinity,
                    //   textAlign: TextAlign.left,
                    //   textStyle: AppUiConstants.textStyleTextFields,
                    //   label: Text("Competition goal"),
                    //   initialSelection: _competitionGoal,
                    //   inputDecorationTheme: InputDecorationTheme(),
                    //   onSelected: (value) => {
                    //     setState(() {
                    //       if (value != null) {
                    //         _competitionGoal = value;
                    //       }
                    //     }),
                    //   },
                    //   trailingIcon: Icon(color: Colors.white, Icons.arrow_drop_down),
                    //   selectedTrailingIcon: Icon(color: Colors.white, Icons.arrow_drop_up),
                    //   menuStyle: MenuStyle(
                    //     backgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.6)),
                    //     alignment: Alignment.center,
                    //   ),
                    //   dropdownMenuEntries: <DropdownMenuEntry<CompetitionGoal>>[
                    //     DropdownMenuEntry(
                    //       value: CompetitionGoal.distance,
                    //       label: "Distance in fastest time",
                    //       style: ButtonStyle(
                    //         foregroundColor: WidgetStatePropertyAll(Colors.white),
                    //         backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    //       ),
                    //     ),
                    //     DropdownMenuEntry(
                    //       value: CompetitionGoal.longestDistance,
                    //       label: "Longest distance in fastest time",
                    //       style: ButtonStyle(
                    //         foregroundColor: WidgetStatePropertyAll(Colors.white),
                    //         backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    //       ),
                    //     ),
                    //     DropdownMenuEntry(
                    //       value: CompetitionGoal.timedActivity,
                    //       label: "Time goal",
                    //       style: ButtonStyle(
                    //         foregroundColor: WidgetStatePropertyAll(Colors.white),
                    //         backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    //       ),
                    //     ),
                    //     DropdownMenuEntry(
                    //       value: CompetitionGoal.timedActivity,
                    //       label: "Steps",
                    //       style: ButtonStyle(
                    //         foregroundColor: WidgetStatePropertyAll(Colors.white),
                    //         backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    //SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                    // Goal of competition
                    TextFormField(
                      readOnly: readOnly,
                      controller: _goalController,
                      style: AppUiConstants.textStyleTextFields,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        labelText: "Distance in km",
                        prefixIcon: Icon(Icons.directions_run, color: Colors.white),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: validateGoal,
                    ),
                  ],
                ),

                Section(
                  title: "Time settings",
                  children: [
                    TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Start date",
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      validator: validateStartDate,
                      onTap: () async {
                        if (widget.enterContext != CompetitionContext.ownerCreate &&
                            widget.enterContext != CompetitionContext.ownerModify) {
                          return;
                        }
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _startDateController, false);
                      },
                    ),
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                    TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      style: AppUiConstants.textStyleTextFields,
                      decoration: InputDecoration(
                        labelText: "End date",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                        prefixIcon: Icon(Icons.calendar_month, color: Colors.white),
                      ),
                      validator: (value) => validateEndDate(value, _startDateController.text.trim()),
                      onTap: () async {
                        if (widget.enterContext != CompetitionContext.ownerCreate &&
                            widget.enterContext != CompetitionContext.ownerModify) {
                          return;
                        }
                        AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _endDateController, false);
                      },
                    ),

                    // Registration deadline
                    SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                    TextFormField(
                      controller: _registrationDeadline,
                      readOnly: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                        labelText: "Register to",
                        labelStyle: AppUiConstants.labelStyleTextFields,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                          validateRegistrationDeadline(_startDateController.text.trim(), _endDateController.text.trim(), value),
                      onTap: () async {
                        if (widget.enterContext != CompetitionContext.ownerCreate &&
                            widget.enterContext != CompetitionContext.ownerModify) {
                          return;
                        }
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _registrationDeadline, false);
                      },
                    ),
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
                                decoration: InputDecoration(
                                  labelText: "Minutes",
                                  prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                                ),
                                style: TextStyle(
                                  color: AppColors.white,
                                ),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: validateMinutes,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                // Hours to complete activity
                Section(
                  title: "Location and participants",
                  children: [
                    TextFormField(
                      controller: _meetingPlaceController,
                      readOnly: true,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.add_location_alt, color: Colors.white),
                        labelText: "Meeting place",
                      ),
                      onTap: () async {
                        onTapAddMeetingPlace();
                      },
                    ),
                    SizedBox(height: AppUiConstants.verticalSpacingButtons),

                    // Invited competitors
                    CustomButton(
                      text: "Participants (${competition?.participantsUid.length ?? 0})",
                      onPressed: () => onPressedListParticipants(context),
                    ),
                  ],
                ),

                // Meeting place
                SizedBox(height: AppUiConstants.verticalSpacingButtons),
                if (widget.enterContext == CompetitionContext.ownerCreate)
                  CustomButton(
                    text: competitionAdded ? "Competition added" : "Add competition",
                    onPressed: competitionAdded ? null : () => handleSaveCompetition(),
                  ),
                if (widget.enterContext == CompetitionContext.ownerModify && (competition?.startDate?.isAfter(DateTime.now()) ?? false))
                  CustomButton(text: "Save changes", onPressed: () => handleSaveCompetition()),
                if (widget.enterContext == CompetitionContext.ownerModify &&
                    (competition?.startDate?.isBefore(DateTime.now()) ?? false)) ...[
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  CustomButton(text: "Close competition", backgroundColor: AppColors.gray, onPressed: () => closeCompetition()),
                ],
                if (widget.enterContext == CompetitionContext.invited && declined == false && acceptedInvitation == false)
                  CustomButton(text: "Accept invitation", onPressed: () => closeCompetition()),

                if (widget.enterContext == CompetitionContext.invited && declined == false && acceptedInvitation == false)
                  CustomButton(text: "Decline invitation", onPressed: () => closeCompetition()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
