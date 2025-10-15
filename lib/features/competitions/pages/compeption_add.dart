import 'dart:math';

import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/common/widgets/user_profile_tile.dart';
import 'package:run_track/constans/app_routes.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/user_service.dart';

import '../../../common/enums/visibility.dart' as enums;
import '../../../common/utils/utils.dart';
import '../../../services/preferences_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/preference_names.dart';
import '../../../theme/ui_constants.dart';
import 'package:flutter/services.dart';
import '../../../common/enums/competition_role.dart';

class AddCompetition extends StatefulWidget {
  final CompetitionRole role;
  final Competition? competitionData;
  const AddCompetition({super.key, required this.role,this.competitionData});

  @override
  State<AddCompetition> createState() {
    return _AddCompetition();
  }
}

class _AddCompetition extends State<AddCompetition> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _registrationDeadline = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityHours = TextEditingController();
  final TextEditingController _maxTimeToCompleteActivityMinutes = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  TextEditingController activityController = TextEditingController();
  bool competitionAdded = false;
  enums.ComVisibility _visibility = enums.ComVisibility.me;
  bool edit = true; // Can we edit a competition?


  Competition? competition;

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
    // Assign a competition
    competition = widget.competitionData;
    if(competition != null){  // Set all fields
      _nameController.text = competition!.name ?? "";
      _descriptionController.text = competition!.description ?? "";
      _startDateController.text = competition!.startDate?.toString() ?? "";
      _endDateController.text = competition!.endDate.toString() ?? "";
      _registrationDeadline.text = competition!.registrationDeadline?.toString() ?? "";
      _maxTimeToCompleteActivityHours.text = competition!.maxTimeToCompleteActivityHours.toString();
      _maxTimeToCompleteActivityMinutes.text = competition!.maxTimeToCompleteActivityMinutes.toString();
      activityController.text = competition!.activityType ?? "";
      _visibility = competition!.visibility;
    }

  }

  Future<void> initializeAsync() async {
    // Set name of user
    if (widget.role == CompetitionRole.owner) {
      _firstNameController.text = AppData.currentUser?.firstName ?? "";
      _lastNameController.text = AppData.currentUser?.lastName ?? "";
    } else if (widget.role == CompetitionRole.participant ||
        widget.role == CompetitionRole.invited ||
        widget.role == CompetitionRole.viewer ||
        widget.role == CompetitionRole.canJoin) {
      final user = await UserService.fetchUser(competition?.organizerUid ?? "");
      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
      }
    }

    await setLastActivityType();
    setState(() {});
  }


  /// Set last competition used in adding
  Future<void> setLastActivityType() async {
    String? lastCompetition = await PreferencesService.loadString(PreferenceNames.lastUsedPreferenceAddCompetition);


    if (lastCompetition != null && lastCompetition.isNotEmpty) {
      if(AppData.currentUser?.activityNames!.contains(lastCompetition) ?? false){
        activityController.text = lastCompetition;
        return;
      }
      activityController.text = AppData.currentUser?.activityNames?.first ?? "Unknown";
    }
  }

  // On tap/ on pressed functions

  void onTapActivityType() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityChoose(currentActivity: activityController.text.trim())));
    void onTapActivity() async {
      final selectedActivity = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ActivityChoose(currentActivity: activityController.text.trim())),
      );

      // If the user selected something, update the TextField
      if (selectedActivity != null && selectedActivity.isNotEmpty) {
        activityController.text = selectedActivity;
        AppData.lastActivityString = selectedActivity;
        // Save it to local preferences
        PreferencesService.saveString(PreferenceNames.lastUsedPreferenceAddCompetition, selectedActivity);
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
      return 'Please pick a start date';
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
    DateTime? start = DateTime.tryParse(startDateValue ?? '');
    DateTime? end = DateTime.tryParse(endDateValue ?? '');
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
    if (start.isAfter(registrationDeadline)) {
      return 'Registration deadline must be after start date';
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
  String? validateHours(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter hours';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    if(int.tryParse(value.trim()) == 0){
      return 'There must be at least one hour to complete activity';
    }

    return null;
  }

  // Max time to complete activity minutes
  String? validateMinutes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter minutes';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    int minutes = int.parse(value.trim());
    if (minutes < 0 || minutes > 59) {
      return 'Minutes must be between 0 and 59';
    }
    return null;
  }


  void handleSaveCompetition() {
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      return;
    }

    DateTime? startDate = _startDateController.text.isNotEmpty ? DateTime.tryParse(_startDateController.text.trim()) : null;

    DateTime? endDate = _endDateController.text.isNotEmpty ? DateTime.tryParse(_endDateController.text.trim()) : null;

    // var competition = Competition(
    //   organizerUid: AppData.currentUser!.uid,
    //   name: _nameController.text.trim(),
    //   description: _descriptionController.text.trim(),
    //   startDate: startDate,
    //   endDate: endDate,
    //   visibility: _visibility,
    // );
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
      ),
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background-first.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Organizer

                  TextField(
                    textAlign: TextAlign.left,
                    readOnly: true,
                    enabled: false,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                      label: Text("Organizer"),
                      filled: true,
                      fillColor: AppColors.textFieldsBackground,
                      border: OutlineInputBorder(
                        borderRadius: AppUiConstants.borderRadiusTextFields,
                        borderSide: BorderSide(color: Colors.white, width: 1),
                      ),
                      prefixIcon: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          AppData.currentUser?.profilePhotoUrl ?? 'https://via.placeholder.com/150',
                        ),
                      ),
                      hintText: '${AppData.currentUser?.firstName ?? ""} ${AppData.currentUser?.lastName ?? ""}',
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  // Name of competition
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  TextFormField(
                    controller: _nameController,
                    style: AppUiConstants.textStyleTextFields,
                    decoration: InputDecoration(
                      border: AppUiConstants.borderTextFields,
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      focusedErrorBorder: AppUiConstants.focusedBorderTextFields,
                      label: Text("Title"),
                      labelStyle: AppUiConstants.labelStyleTextFields,
                      filled: true,
                      fillColor: AppColors.textFieldsBackground,
                    ),
                    validator: validateName,
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Description
                  TextFormField(
                    maxLines: 3,
                    controller: _descriptionController,
                    decoration: InputDecoration(
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
                          controller: activityController,
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
                                onPressed: () => ActivityChoose(currentActivity: activityController.text.trim()),
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
                      readOnly: true,
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
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _startDateController);
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
                        AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _endDateController);
                      },
                    ),
                  ),

                  // Registration deadline
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),

                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _registrationDeadline,
                      readOnly: true,
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
                        await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), _registrationDeadline);
                      },
                    ),
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
                              readOnly: false,
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
                              readOnly: false,
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
                              validator: validateMinutes,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Invited competitors
                  SizedBox(height: AppUiConstants.verticalSpacingButtons),


                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Invite competitors",
                          onPressed: null,
                          gradientColors: [
                            competitionAdded ? Colors.red : Color(0xFFFFB74D),
                            competitionAdded ? Colors.red : Color(0xFFFF9800),
                            competitionAdded ? Colors.red : Color(0xFFF57C00),
                          ],
                        ),
                      ),
                      SizedBox(width: AppUiConstants.horizontalSpacingButtons),
                      Expanded(
                        child: CustomButton(
                          text: "List of competitors",
                          onPressed: null,
                          gradientColors: [
                            competitionAdded ? Colors.red : Color(0xFFFFB74D),
                            competitionAdded ? Colors.red : Color(0xFFFF9800),
                            competitionAdded ? Colors.red : Color(0xFFF57C00),
                          ],
                        ),
                      ),
                    ],
                  ),



                  SizedBox(height: AppUiConstants.verticalSpacingButtons),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: competitionAdded ? "Competition added" : "Add competition",
                      onPressed: competitionAdded ? null : () => handleSaveCompetition(),
                      gradientColors: [
                        competitionAdded ? Colors.red : Color(0xFFFFB74D),
                        competitionAdded ? Colors.red : Color(0xFFFF9800),
                        competitionAdded ? Colors.red : Color(0xFFF57C00),
                      ],
                    ),
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
