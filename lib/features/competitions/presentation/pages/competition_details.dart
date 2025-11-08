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

enum CompetitionState {
  canStart,
  inProgress,
  finished
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

  CompetitionState? _competitionState = null;
  Competition? competition;
  String appBarTitle = "Competition details";
  bool competitionAdded = false;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  bool canPause = true;
  bool edit = true; // Can we edit a competition?
  bool readOnly = false;
  bool acceptedInvitation = false; // If users is invited and enter context is context invited users can accept invitation or not
  bool declined = false; // If users is invited and enter context is context invited users can decline invitation
  String message = "";

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
    _setAppBarTitle();
    _setCompetitionState();
  }

  void _setCompetitionState() {
    bool isActive = competition != null && competition!.startDate != null && competition!.endDate != null
        && competition!.startDate!.isBefore(DateTime.now()) &&
        competition!.endDate!.isAfter(DateTime.now());
    bool isFinished = competition?.results?.containsKey(FirebaseAuth.instance.currentUser?.uid) ?? false;
    bool isNotCurrentlyAssigned = AppData.instance.currentCompetition?.competitionId != competition!.competitionId;
    bool ownerCreate = widget.enterContext != CompetitionContext.ownerCreate;
    bool inProgress = TrackState.instance.currentCompetition == competition?.competitionId
        && TrackState.trackingState != TrackingState.stopped;
    if (isActive && !isFinished && !ownerCreate && isNotCurrentlyAssigned) {
      _competitionState = CompetitionState.canStart;
      message = "You can start competition!";
    } else if (isActive && isFinished && !ownerCreate) {
      _competitionState = CompetitionState.finished;
      message = "You have finished this competition";
    } else if (isActive && !isFinished && ownerCreate && inProgress) {
      _competitionState = CompetitionState.inProgress;
      message = "Competition in progress..";
    }
  }


  void _setAppBarTitle() {
    if (widget.enterContext == CompetitionContext.ownerCreate) {
      appBarTitle = "Add competition";
    }
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
    _goalController.text = data.distanceToGo.toString();
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

      distanceToGo: double.tryParse(_goalController.text.trim()) ?? 0,

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
      distanceToGo: 10,
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




  /// On pressed list participants
  void onPressedListParticipants(BuildContext context) async {
    EnterContextUsersList enterContext = EnterContextUsersList.participantsModify;
    if (widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) {
      enterContext = EnterContextUsersList.participantsReadOnly;
    }

    final result = await Navigator.pushNamed(context,
        AppRoutes.usersList, arguments: {
          "usersUid": competition?.participantsUid ?? {},
          "usersUid2": competition?.invitedParticipantsUid ?? {},
          "usersUid3": {},
          "enterContext": enterContext,
        });
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

  /// Set this competition as current competition
  void _setAsCurrentCompetition() {
    if (widget.competitionData != null && AppData.instance.currentUser != null &&
        competition!.competitionId != AppData.instance.currentCompetition?.competitionId &&
        competition!.startDate!.isBefore(DateTime.now()) && competition!.endDate!.isAfter(DateTime.now())) {
      Set
      AppData.instance.currentCompetition = competition;
      AppData.instance.currentUser?.currentCompetition = competition!.competitionId;
      UserService.updateUser(AppData.instance.currentUser!);
    }
  }

  /// Clear current competition
  void _clearCurrentCompetition() {
    AppData.instance.currentCompetition = null;
    AppData.instance.currentUser?.currentCompetition = "";
    UserService.updateUser(AppData.instance.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // Info banner
                if(_competitionState != null && _competitionState == CompetitionState.inProgress)


                  if(competition?.startDate != null && competition?.endDate != null && competition!.startDate!.isBefore(DateTime.now()) &&
                      competition!.endDate!.isAfter(DateTime.now()) &&
                      !(competition?.results?.containsKey(FirebaseAuth.instance.currentUser?.uid) ?? false) &&
                      widget.enterContext != CompetitionContext.ownerCreate)...[

                    SizedBox(
                      height: AppUiConstants.verticalSpacingButtons,
                    ),
                    CustomButton(
                        text: competition?.competitionId != AppData.instance.currentCompetition?.competitionId
                            ? "Set as current competition"
                            : "Current competition",
                        onPressed: _setAsCurrentCompetition
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
