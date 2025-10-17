import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../../common/utils/app_constants.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../theme/colors.dart';

class AdditionalInfo extends StatefulWidget {
  _AdditionalInfoState createState() => _AdditionalInfoState();
}

class _AdditionalInfoState extends State<AdditionalInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;

  String? validateFields(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter your $fieldName";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppUiConstants.paddingOutsideForm,
      child: Center(
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.formBackgroundOverlay,
              borderRadius: AppUiConstants.borderRadiusForm,
            ),
            child: Padding(
              padding: AppUiConstants.paddingInsideForm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    // Date of birth
                    controller: _dateController,
                    readOnly: true,
                    validator: (value) => validateFields(value, "DateOfBirth"),
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: AppUiConstants.borderRadiusTextFields,
                      ),
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      contentPadding: AppUiConstants.contentPaddingTextFields,
                    ),
                    onTap: () async {
                      // Date picker
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        String formattedDate = "${pickedDate.year.toString().padLeft(4,'0')}-"
                            "${pickedDate.month.toString().padLeft(2,'0')}-"
                            "${pickedDate.day.toString().padLeft(2,'0')}";
                        _dateController.text = formattedDate;
                      }
                    },
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    validator: (value) => validateFields(value, "gender"),
                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: AppUiConstants.borderRadiusTextFields,
                      ),
                      enabledBorder: AppUiConstants.enabledBorderTextFields,
                      focusedBorder: AppUiConstants.focusedBorderTextFields,
                      errorBorder: AppUiConstants.errorBorderTextFields,
                      contentPadding: AppUiConstants.contentPaddingTextFields,
                    ),
                    items: AppConstants.genders.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                  ),

                  SizedBox(height: AppUiConstants.verticalSpacingButtons),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: CustomButton(
                      text: "Register",
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Fields are valid
                          Navigator.of(context).pop({
                            "dob": _dateController.text,
                            "gender": _selectedGender!,
                          });
                        } else {
                          AppUtils.showMessage(
                            context,
                            "Please fill all required fields",
                          );
                        }
                      },
                      textSize: 20,

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
