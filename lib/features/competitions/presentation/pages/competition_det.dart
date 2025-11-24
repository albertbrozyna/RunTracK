import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';
import 'package:run_track/features/competitions/data/models/competition_result.dart';
import 'package:run_track/features/competitions/presentation/widgets/basic_info_section.dart';
import 'package:run_track/features/competitions/presentation/widgets/build_bottom_buttons.dart';
import 'package:run_track/features/competitions/presentation/widgets/time_settings_section.dart';
import 'package:run_track/features/competitions/presentation/widgets/top_info_banner.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/preference_names.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/enums/participant_management_action.dart';
import '../../../../core/enums/visibility.dart' as enums;
import '../../data/models/competition.dart';
import '../../data/services/competition_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/alert_dialog.dart';
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

enum CompetitionState { canStart, inProgress, finished,currentlyAssigned,notAssigned }


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
  CompetitionResult? competitionResult;
  late Competition? competitionBeforeSave = widget.competitionData;
  String appBarTitle = "Competition details";
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  bool readOnly = false;
  String message = "";
  bool saveInProgress = false;
  bool saved = false;
  bool leavingPage = false;
  bool _isLoading = false;
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
    _isLoading = true;
    initialize();
    initializeAsync();
  }

  void initialize() {
    AuthService.instance.checkAppUseState(context);
    _setReadOnlyState();
    _setupCompetitionData();
    _setAppBarTitle();
  }

  Future<void> _getResults()async {
    if(widget.enterContext != CompetitionContext.ownerCreate){
      final result = await CompetitionService.fetchResult(widget.competitionData?.competitionId ?? '');
      if(!mounted)return;
      if(result != null){
        setState(() {
          competitionResult = result;
        });
      }
    }
  }

  void _setAppBarTitle() {
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      appBarTitle = "Add competition";
    }
  }

  void _setReadOnlyState() {
    if ((widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) || (widget.competitionData?.startDate?.isBefore(DateTime.now()) ?? false)) {
      readOnly = true;
    }
  }

  void _setupCompetitionData() {
    if (widget.competitionData != null) {
      AppData.instance.currentCompetition =  widget.competitionData!;
      _populateFormFromData(AppData.instance.currentCompetition!);
    } else {
      AppData.instance.currentCompetition = _createNewCompetition();
    }
  }

  /// Sync data to controllers
  void _populateFormFromData(Competition data) {
    _nameController.text = data.name;
    if(data.organizerUid == FirebaseAuth.instance.currentUser?.uid){
      _organizerController.text = AppData.instance.currentUser?.fullName ?? "User Unknown";
    }else{
     UserService.fetchUserForBlock(AppData.instance.currentCompetition?.organizerUid ?? "")
          .then((user) {
        setState(() {
          String fullName = user?.firstName ?? "User";
          fullName += user?.lastName ?? "Unknown";
          _organizerController.text = fullName;
        });
      })
          .catchError((error) {
        print("Error fetching user data: $error");
      });
    }
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

  Competition _createNewCompetition() {
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      if (widget.initTab == 1) {
        _visibility = enums.ComVisibility.friends;
      } else if (widget.initTab == 2) {
        _visibility = enums.ComVisibility.everyone;
      }
    }

    return  Competition(
      organizerUid: AppData.instance.currentUser?.uid ?? "",
      name: "",
      description: "",
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      visibility: _visibility,
      distanceToGo: 10,
      participantsUid: {FirebaseAuth.instance.currentUser?.uid ?? ""}, // Set owner as first participant
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
      final user = await UserService.fetchUser(AppData.instance.currentCompetition!.organizerUid);
      if (user != null) {
        setState(() {
          _organizerController.text = user.firstName;
          _organizerController.text += ' ${user.lastName}';
        });
      }
    }

    if(widget.enterContext == CompetitionContext.ownerCreate){
      await setLastActivityType();  // Set last used activity
    }
    await _getResults();

    setState(() {
      _isLoading = false;
    });
  }

  void setVisibility(enums.ComVisibility visibility) {
    setState(() {
      _visibility = visibility;
    });
  }

  /// Set last activity type that was used in adding
  Future<void> setLastActivityType() async {
    String? lastCompetition = await PreferencesService.loadString(PreferenceNames.lastUsedPreferenceAddCompetition);

    if (lastCompetition != null && lastCompetition.isNotEmpty) {
      if (AppData.instance.currentUser?.activityNames.contains(lastCompetition) ?? false) {
        _activityController.text = lastCompetition;
        return;
      }
      _activityController.text = AppData.instance.currentUser?.activityNames.first ?? "Unknown";
    }
  }

  /// Close competition
  void closeCompetition() async {
    bool res = await CompetitionService.closeCompetitionBeforeEndTime(AppData.instance.currentCompetition!.competitionId);
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
    final baseCompetition = AppData.instance.currentCompetition!;

    return Competition(
      competitionId: baseCompetition.competitionId,
      organizerUid: baseCompetition.organizerUid,
      invitedParticipantsUid: baseCompetition.invitedParticipantsUid,
      participantsUid: baseCompetition.participantsUid,
      location: baseCompetition.location,
      locationName: baseCompetition.locationName,
      closedBeforeEndTime: baseCompetition.closedBeforeEndTime,
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

  void deleteCompetition() async {
    final screenContext = context;
    final competitionId = widget.competitionData?.competitionId;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          titleText: "Warning",
          contentText:
          "Are you sure you want to delete this activity?\n\n"
              "This action cannot be undone.",
          textRight: "Yes",
          textLeft: "Cancel",
          colorBackgroundButtonRight: AppColors.danger,
          colorButtonForegroundRight: AppColors.white,

          onPressedRight: () {
            Navigator.of(dialogContext).pop(true);
          },

          onPressedLeft: () {
            Navigator.of(dialogContext).pop(false);
          },
        );
      },
    );

    if (didConfirm != true) {
      return;
    }

    if (!mounted) return;
    final bool res = await CompetitionService.deleteCompetition(competitionId ?? "");
    if (!mounted) return;

    if (res && screenContext.mounted) {
      AppUtils.showMessage(screenContext, "Competition deleted successfully");
      Navigator.of(context).pop();
    } else {
      if(!screenContext.mounted) return;
      AppUtils.showMessage(screenContext, "Error deleting competition");
    }
  }

  void acceptInvitation() async {
    if (await CompetitionService.manageParticipant(
          competitionId: AppData.instance.currentCompetition!.competitionId,
          targetUserId: FirebaseAuth.instance.currentUser?.uid ?? "",
          action: ParticipantManagementAction.acceptInvitation,
        ) ==
        false) {
      if (!mounted) return;
      AppUtils.showMessage(context, "Error accepting invitation");
      return;
    }
  }

  void declineInvitation() async {
    if (await CompetitionService.manageParticipant(
          competitionId:  AppData.instance.currentCompetition!.competitionId,
      targetUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          action:  ParticipantManagementAction.declineInvitation,
        ) ==
        false) {
      if (!mounted) return;
      AppUtils.showMessage(context, "Error accepting invitation");
      return;
    }
  }

  void joinCompetition() async {
    if (await CompetitionService.manageParticipant(
          competitionId: AppData.instance.currentCompetition!.competitionId,
          targetUserId:  FirebaseAuth.instance.currentUser?.uid ?? "",
          action:  ParticipantManagementAction.joinCompetition,
        ) ==
        false) {
      if (!mounted) return;
      AppUtils.showMessage(context, "Error accepting invitation");
      return;
    }

  }

  void resignFromCompetition() async {
    if (await CompetitionService.manageParticipant(
          competitionId: AppData.instance.currentCompetition!.competitionId,
          targetUserId:  FirebaseAuth.instance.currentUser?.uid ?? "",
          action:  ParticipantManagementAction.resignFromCompetition,
        ) ==
        false) {
      if (!mounted) return;
      AppUtils.showMessage(context, "Error accepting invitation");
      return;
    }
  }

  /// Save competition to database
  void handleSaveCompetition() async {
    if (saveInProgress == false) {
        saveInProgress = true;
    }
    // if (!_formKey.currentState!.validate()) {
    //   saveInProgress = false;
    //   return;
    // }

    final currentContext = context;

    AppData.instance.currentCompetition = _getDataFromForm();
    Competition? newCompetition = await CompetitionService.saveCompetition(AppData.instance.currentCompetition!);

    if (!mounted) return;

    if (newCompetition != null) {
      competitionBeforeSave = AppData.instance.currentCompetition!; // Save competition before save state

      if (widget.enterContext == CompetitionContext.ownerCreate && saved == false) {

        AppData.instance.currentCompetition = newCompetition;

        // Update user counter for created competitions
        UserService.updateFieldsInTransaction(AppData.instance.currentUser?.uid ?? "", {
          'competitionsCount' : FieldValue.increment(1),
        });
        if(!currentContext.mounted) return;
        AppUtils.showMessage(currentContext, "Competition saved successfully", messageType: MessageType.success);
        setState(() {
          saved = true;
        });
      } else if (widget.enterContext == CompetitionContext.ownerModify || saved) {

        if(!currentContext.mounted) return;
        AppUtils.showMessage(currentContext, "Changes saved successfully");
      }
    } else {
      if(!currentContext.mounted) return;
      AppUtils.showMessage(currentContext, "Error saving competition");
    }
    saveInProgress = false;
  }


  /// Leave page if changes are done
  void leavePage() async{
    if(leavingPage){
      return;
    }
    leavingPage = true;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();  // Hide snack to avoid _debugLocked

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    var compData = _getDataFromForm();

    // If there is no changes, just pop
    if (competitionBeforeSave == null || (competitionBeforeSave?.isEqual(compData) ?? false)) {
      Navigator.of(context).pop();
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          titleText: "Warning",
          contentText:
              "You have unsaved changes\n\n"
              "If you leave now, your changes will be lost.\n\n"
              "Are you sure you want to leave?",
          textLeft: "Cancel",
          textRight: "Yes",
          colorBackgroundButtonRight: AppColors.danger,
          colorButtonForegroundRight: AppColors.white,
          colorBackgroundButtonLeft: AppColors.gray,
          colorButtonForegroundLeft: AppColors.white,
          onPressedLeft: () {
            Navigator.of(dialogContext).pop();
            leavingPage = false;
          },
          onPressedRight: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        );
      },
    );
    leavingPage = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        leavePage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: [
            if (widget.enterContext == CompetitionContext.ownerModify)
              IconButton(
                onPressed: deleteCompetition,
                icon: Icon(Icons.delete, color: Colors.white),
              ),
          ],
        ),
        body: _isLoading ? AppLoadingIndicator() :
        Form(
          key: _formKey,
          child: PageContainer(
            assetPath: AppImages.appBg4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TopInfoBanner(competition: AppData.instance.currentCompetition!,competitionResult: competitionResult ?? CompetitionResult(competitionId: "", ranking: []), enterContext: widget.enterContext),

                  BasicInfoSection(
                    readOnly: readOnly,
                    visibility: _visibility,
                    competition: AppData.instance.currentCompetition!,
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
                    competition: AppData.instance.currentCompetition!,
                    meetingPlaceController: _meetingPlaceController,
                    saved: saved,
                  ),

                  BottomButtons(
                    enterContext: widget.enterContext,
                    competition: AppData.instance.currentCompetition!,
                    handleSaveCompetition: handleSaveCompetition,
                    acceptInvitation: acceptInvitation,
                    declineInvitation: declineInvitation,
                    joinCompetition: joinCompetition,
                    resignFromCompetition: resignFromCompetition,
                    saved: saved,
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
