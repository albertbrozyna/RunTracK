import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/track/pages/activity_choose.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/user_service.dart';

import '../../../common/enums/visibility.dart' as enums;
import '../../../theme/colors.dart';
import '../../../theme/ui_constants.dart';

class AddCompetition extends StatefulWidget {
  @override
  _AddCompetition createState() {
    return _AddCompetition();
  }
}

class _AddCompetition extends State<AddCompetition> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController activityController = TextEditingController();
  bool competitionAdded = false;

  // TODO idea save last visibility as preferences
  enums.Visibility _visibility = enums.Visibility.me;

  void handleSaveCompetition() {
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      return;
    }

    DateTime? startDate = _startDateController.text.isNotEmpty
        ? DateTime.tryParse(_startDateController.text.trim())
        : null;

    DateTime? endDate = _endDateController.text.isNotEmpty
        ? DateTime.tryParse(_endDateController.text.trim())
        : null;

    var competition = Competition(
      organizerUid: AppData.currentUser!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: startDate,
      endDate: endDate,
      competitionType: activityController.text.trim(),
      visibility: _visibility,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "Add competition",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-first.jpg"),
            fit: BoxFit.cover,

            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Name of competition
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    label: Text("Title", style: TextStyle(color: Colors.white)),
                    labelStyle: TextStyle(fontSize: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                // Description
                TextField(
                  maxLines: 3,
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    // Normal border
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24, width: 1),
                    ),
                    label: Text(
                      "Description",
                      style: TextStyle(color: Colors.white),
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    filled: true,
                  ),
                  style: TextStyle(color: Colors.white),
                ),

                SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                // Activity type of competition
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.left,
                        controller: activityController,
                        readOnly: true,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          label: Text(
                            "Activity type",
                            style: TextStyle(color: Colors.white),
                          ),
                          suffixIcon: Padding(
                            padding: EdgeInsets.all(
                              AppUiConstants.paddingTextFields,
                            ),
                            child: IconButton(
                              onPressed: () => ActivityChoose(
                                currentActivity: activityController.text.trim(),
                              ),
                              icon: Icon(Icons.list, color: Colors.white),
                            ),
                          ),
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          filled: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Visibility
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: IconThemeData(color: Colors.white),
                        ),
                        child: DropdownMenu(
                          textStyle: TextStyle(color: Colors.white),
                          label: Text(
                            "Visibility",
                            style: TextStyle(color: Colors.white),
                          ),
                          initialSelection: _visibility,
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                          ),
                          width: double.infinity,
                          textAlign: TextAlign.left,
                          // Selecting visibility
                          onSelected: (enums.Visibility? visibility) {
                            setState(() {
                              if (visibility != null) {
                                _visibility = visibility;
                              }
                            });
                          },
                          // Icon
                          trailingIcon: Icon(
                            color: Colors.white,
                            Icons.arrow_drop_down,
                          ),
                          selectedTrailingIcon: Icon(
                            color: Colors.white,
                            Icons.arrow_drop_up,
                          ),

                          menuStyle: MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              AppColors.primary.withValues(alpha: 0.6),
                            ),
                            alignment: Alignment.center,
                          ),
                          dropdownMenuEntries:
                              <DropdownMenuEntry<enums.Visibility>>[
                                DropdownMenuEntry(
                                  value: enums.Visibility.me,
                                  label: "Only Me",
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(
                                      Colors.white,
                                    ),
                                    backgroundColor: MaterialStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                                ),
                                DropdownMenuEntry(
                                  value: enums.Visibility.friends,
                                  label: "Friends",
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(
                                      Colors.white,
                                    ),
                                    backgroundColor: MaterialStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                                ),
                                DropdownMenuEntry(
                                  value: enums.Visibility.everyone,
                                  label: "Everyone",
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(
                                      Colors.white,
                                    ),
                                    backgroundColor: MaterialStatePropertyAll(
                                      Colors.transparent,
                                    ),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateController,
                        readOnly: true,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today,color: Colors.white,),
                          labelText: "Start date",
                          labelStyle: TextStyle(
                              color: Colors.white
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100)
                          );
                          if (pickedDate != null) {
                            String formattedDate =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            _startDateController.text = formattedDate;
                          }
                        },
                      ),
                    ),
                    // End date
                    SizedBox(width: 15),

                    Expanded(
                      child: TextField(
                        controller: _endDateController,
                        readOnly: true,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: "End date",
                          labelStyle: TextStyle(
                            color: Colors.white
                          ),
                          prefixIcon: Icon(Icons.calendar_month ,color: Colors.white,),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100)
                          );
                          if (pickedDate != null) {
                            String formattedDate =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            _endDateController.text = formattedDate;
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 8,
                ),
                // TODO Change color after saving activity
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    text: competitionAdded
                        ? "Competition added"
                        : "Add competition",
                    onPressed: competitionAdded
                        ? null
                        : () => handleSaveCompetition(),
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
    );
  }
}
