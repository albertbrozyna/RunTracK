import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/form_container.dart';
import 'package:run_track/theme/app_colors.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../../common/utils/app_constants.dart';
import '../../../../common/widgets/custom_button.dart';

class AdditionalInfo extends StatefulWidget {
  const AdditionalInfo({super.key});

  @override
  State<AdditionalInfo> createState() => _AdditionalInfoState();
}

class _AdditionalInfoState extends State<AdditionalInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;

  String? validateFields(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Please enter your $fieldName";
    }

    if(fieldName == 'DateOfBirth'){
      DateTime? date = DateTime.tryParse(value.trim());
      if(date == null){
        return "Please enter a valid date";
      }
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
          child: FormContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    // Date of birth
                    style: TextStyle(color: Colors.white,fontSize: 16),
                    readOnly: true,
                    controller: _dateController,
                    validator: (value) => validateFields(value, "DateOfBirth"),
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      // Date picker
                      AppUtils.pickDate(context, DateTime(1900), DateTime.now(),_dateController, true);
                    },
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                  // Gender
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.primary,
                    style: TextStyle(color: Colors.white,),
                    initialValue: _selectedGender,
                    validator: (value) => validateFields(value, "gender"),
                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: Icon(Icons.person_outline),
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

                    CustomButton(
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
                ],
              ),
          ),
        ),
      ),
    );
  }
}
