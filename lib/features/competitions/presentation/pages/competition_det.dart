import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/features/competitions/presentation/widgets/basic_info_section.dart';
import 'package:run_track/features/competitions/presentation/widgets/time_settings_section.dart';
import 'package:run_track/features/competitions/presentation/widgets/top_info_banner.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/preference_names.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/enums/visibility.dart' as enums;
import '../../../../core/models/competition.dart';
import '../../../../core/services/competition_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/alert_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../widgets/competition_goal_section.dart';
import '../widgets/location_and_participants_section.dart';

class CompetitionDetailsPage extends StatefulWidget {
  final CompetitionContext enterContext;
  final Competition? competitionData;
  final int initTab; // Tab index to set a start visibility

  const CompetitionDetailsPage({super.key, required this.enterContext, this.competitionData, required this.initTab});

  @override
  State<CompetitionDetailsPage> createState() => _CompetitionDetailsPageState();
}

enum CompetitionState { canStart, inProgress, finished }

class _CompetitionDetailsPageState extends State<CompetitionDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _registerDeadlineController = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityHoursController = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityMinutesController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _meetingPlaceController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  late Competition competition;
  String appBarTitle = "Competition details";
  bool competitionAdded = false;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  bool canPause = true;
  bool edit = true; // Can we edit a competition?
  bool readOnly = false;
  bool acceptedInvitation = false; // If users is invited and enter context is context invited users can accept invitation or not
  bool declined = false; // If users is invited and enter context is context invited users can decline invitation
  String message = "";

  bool saveInProgress = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _registerDeadlineController.dispose();
    _maxTimeToCompleteActivityHoursController.dispose();
    _maxTimeToCompleteActivityMinutesController.dispose();
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
    _setAppBarTitle();
  }

  void _setAppBarTitle() {
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      appBarTitle = "Add competition";
    }
  }

  void _setReadOnlyState() {
    if (widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) {
      readOnly = true;
    }
  }

  void _setupCompetitionData() {
    if (widget.competitionData != null) {
      competition = widget.competitionData!;
      _populateFormFromData(competition);
    } else {
      _createNewCompetition();
    }
  }

  /// Sync data to controllers
  void _populateFormFromData(Competition data) {
    _nameController.text = data.name;
    _organizerController.text = data.name;
    _descriptionController.text = data.description ?? "";
    _startTimeController.text = AppUtils.formatDateTime(data.startDate);
    _endTimeController.text = AppUtils.formatDateTime(data.endDate);
    _registerDeadlineController.text = AppUtils.formatDateTime(data.registrationDeadline);
    _maxTimeToCompleteActivityHoursController.text = data.maxTimeToCompleteActivityHours.toString();
    _maxTimeToCompleteActivityMinutesController.text = data.maxTimeToCompleteActivityMinutes.toString();
    _activityController.text = data.activityType ?? "";
    _visibility = data.visibility;
    _goalController.text = data.distanceToGo.toString();
    _setMeetingPlaceText(data.location, data.locationName);
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
      distanceToGo: 10,
      participantsUid: {FirebaseAuth.instance.currentUser!.uid}, // Set owner as first participant
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
      final user = await UserService.fetchUser(competition.organizerUid);
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

  void setVisibility(enums.ComVisibility visibility) {
    _visibility = visibility;
  }

  /// Set last activity type that was used in adding
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

  /// Close competition
  void closeCompetition() async {
    bool res = await CompetitionService.closeCompetitionBeforeEndTime(competition.competitionId);
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

  Competition _getDataFromForm() {
    final baseCompetition = competition;

    return Competition(
      competitionId: baseCompetition.competitionId,
      organizerUid: baseCompetition.organizerUid,
      invitedParticipantsUid: baseCompetition.invitedParticipantsUid,
      participantsUid: baseCompetition.participantsUid,
      location: baseCompetition.location,
      locationName: baseCompetition.locationName,
      closedBeforeEndTime: baseCompetition.closedBeforeEndTime,
      photos: baseCompetition.photos,
      createdAt: baseCompetition.createdAt ?? DateTime.now(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      activityType: _activityController.text.trim(),
      visibility: _visibility,

      startDate: DateTime.tryParse(_startTimeController.text.trim()) ?? DateTime.now(),
      endDate: DateTime.tryParse(_endTimeController.text.trim()) ?? DateTime.now(),
      registrationDeadline: DateTime.tryParse(_registerDeadlineController.text.trim()) ?? DateTime.now(),

      distanceToGo: double.tryParse(_goalController.text.trim()) ?? 0,

      maxTimeToCompleteActivityHours: int.tryParse(_maxTimeToCompleteActivityHoursController.text.trim()),
      maxTimeToCompleteActivityMinutes: int.tryParse(_maxTimeToCompleteActivityMinutesController.text.trim()),
    );
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

  /// Save competition to database
  void handleSaveCompetition() async {
    if(saveInProgress == false){
      saveInProgress = true;
    }
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

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) Navigator.of(context).pop(competition);
      } else if (widget.enterContext == CompetitionContext.ownerModify) {
        if (mounted) {
          AppUtils.showMessage(context, "Changes saved successfully");
        }
        competitionAdded = true;
      }
    } else {
      if (mounted) AppUtils.showMessage(context, "Error saving competition");
    }
    saveInProgress = false;
  }

  /// Leave page if changes are done
  void leavePage(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !false,
      onPopInvokedWithResult: (didPop, result) => leavePage(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
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
                  TopInfoBanner(competition: competition, enterContext: widget.enterContext),
      
                  BasicInfoSection(
                    readOnly: readOnly,
                    visibility: _visibility,
                    competition: competition,
                    organizerController: _organizerController,
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    setVisibility: setVisibility,
                  ),
      
                  CompetitionGoalSection(readOnly: readOnly, activityController: _activityController, goalController: _goalController),
      
                  TimeSettingsSection(
                    enterContext: widget.enterContext,
                    readOnly: readOnly,
                    startTimeController: _startTimeController,
                    endTimeController: _endTimeController,
                    registerDeadlineController: _registerDeadlineController,
                    maxTimeToCompleteActivityHoursController: _maxTimeToCompleteActivityHoursController,
                    maxTimeToCompleteActivityMinutesController: _maxTimeToCompleteActivityMinutesController,
                  ),
      
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
      
                  LocationAndParticipantsSection(
                    enterContext: widget.enterContext,
                    competition: competition,
                    meetingPlaceController: _meetingPlaceController,
                  ),
      
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  if (widget.enterContext == CompetitionContext.ownerCreate)
                    CustomButton(
                      text: "Add competition",
                      onPressed: handleSaveCompetition,
                    ),
                  if (widget.enterContext == CompetitionContext.ownerModify && (competition.startDate?.isAfter(DateTime.now()) ?? false))
                    CustomButton(text: "Save changes", onPressed: () => handleSaveCompetition()),
                  if (widget.enterContext == CompetitionContext.ownerModify &&
                      (competition.startDate?.isBefore(DateTime.now()) ?? false)) ...[
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
      ),
    );
  }
}
