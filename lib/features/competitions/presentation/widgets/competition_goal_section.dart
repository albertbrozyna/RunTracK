

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/preference_names.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/widgets/section.dart';
import '../../data/services/validators.dart';

class CompetitionGoalSection extends StatefulWidget{
  bool readOnly;
  TextEditingController activityController;
  TextEditingController goalController;
  CompetitionGoalSection({super.key,required this.readOnly,required this.activityController,required this.goalController});

  @override
  State<CompetitionGoalSection>  createState() => _CompetitionGoalSectionState();
}

class _CompetitionGoalSectionState extends State<CompetitionGoalSection> {

  // Activity type
  String? validateActivity(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please select an activity';
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

  void onTapActivityType(BuildContext context) async {
    final selectedActivity = await Navigator.pushNamed(context, AppRoutes.activityChoose);
    if (selectedActivity is String && selectedActivity.isNotEmpty) {
      widget.activityController.text = selectedActivity;
      AppData.instance.lastActivityString = selectedActivity;
      PreferencesService.saveString(PreferenceNames.lastUsedPreferenceAddCompetition, selectedActivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return    Section(
      title: "Competition goal",
      children: [
        // Activity type of competition
        TextFormField(
          controller: widget.activityController,
          style: AppUiConstants.textStyleTextFields,
          textAlign: TextAlign.left,
          readOnly: true,
          decoration: InputDecoration(
            labelText: "Activity type",
            labelStyle: AppUiConstants.labelStyleTextFields,
            suffixIcon: Padding(
              padding: EdgeInsets.all(AppUiConstants.paddingTextFields),
              child: IconButton(
                onPressed: widget.readOnly ? null : () => onTapActivityType(context),
                icon: Icon(Icons.list, color: Colors.white),
              ),
            ),
          ),
          validator: validateActivity,
        ),
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),

        TextFormField(
          readOnly: widget.readOnly,
          controller: widget.goalController,
          style: AppUiConstants.textStyleTextFields,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            labelText: "Distance in km",
            prefixIcon: Icon(Icons.directions_run, color: Colors.white),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],          validator: validateGoal,
        ),
      ],
    );
  }
}