import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/section.dart' show Section;

class TimeSettingsSection extends StatefulWidget{
  final CompetitionContext enterContext;
  final bool readOnly;
 final TextEditingController startTimeController;
 final TextEditingController endTimeController;
 final TextEditingController registerDeadlineController;
 final TextEditingController maxTimeToCompleteActivityHoursController;
 final TextEditingController maxTimeToCompleteActivityMinutesController;

 const TimeSettingsSection({super.key,required this.enterContext,required this.readOnly,required this.startTimeController,required this.endTimeController,required this.registerDeadlineController,required this.maxTimeToCompleteActivityHoursController,required this.maxTimeToCompleteActivityMinutesController});

  @override
  State<TimeSettingsSection>  createState() => _TimeSettingsSectionState();
}


class _TimeSettingsSectionState extends State<TimeSettingsSection> {

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
  String? validateHours(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please pick hour';
    }

    if (value
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
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please pick minutes';
    }

    if (value
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


  @override
  Widget build(BuildContext context) {
    return Section(
      title: "Time settings",
      children: [
        TextFormField(
          controller: widget.startTimeController,
          readOnly: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Start date",
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
          ),
          validator: validateStartDate,
          onTap: widget.readOnly ? null : () async {
            if (widget.enterContext != CompetitionContext.ownerCreate &&
                widget.enterContext != CompetitionContext.ownerModify) {
              return;
            }
            await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), widget.startTimeController, false);
          },
        ),
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),

        TextFormField(
          controller: widget.endTimeController,
          readOnly: true,
          style: AppUiConstants.textStyleTextFields,
          decoration: InputDecoration(
            labelText: "End date",
            labelStyle: AppUiConstants.labelStyleTextFields,
            prefixIcon: Icon(Icons.calendar_month, color: Colors.white),
          ),
          validator: (value) => validateEndDate(value, widget.startTimeController.text.trim()),
          onTap: widget.readOnly ? null :  () async {
            if (widget.enterContext != CompetitionContext.ownerCreate &&
                widget.enterContext != CompetitionContext.ownerModify) {
              return;
            }
            AppUtils.pickDate(context, DateTime.now(), DateTime(2100), widget.endTimeController, false);
          },
        ),

        // Registration deadline
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),

        TextFormField(
          controller: widget.registerDeadlineController,
          readOnly: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
            labelText: "Register to",
            labelStyle: AppUiConstants.labelStyleTextFields,
          ),
          validator: (value) =>
              validateRegistrationDeadline(widget.startTimeController.text.trim(), widget.endTimeController.text.trim(), value),
          onTap: widget.readOnly ? null : () async {
            if (widget.enterContext != CompetitionContext.ownerCreate &&
                widget.enterContext != CompetitionContext.ownerModify) {
              return;
            }
            await AppUtils.pickDate(context, DateTime.now(), DateTime(2100), widget.registerDeadlineController, false);
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
                    controller: widget.maxTimeToCompleteActivityHoursController,
                    readOnly: widget.readOnly,
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
                    controller: widget.maxTimeToCompleteActivityMinutesController,
                    readOnly: widget.readOnly,
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
    );
  }


}