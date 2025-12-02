import 'package:flutter/material.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/custom_button.dart';
import 'field_form.dart';


class AdditionalInfo extends StatefulWidget {
  const AdditionalInfo({super.key});

  @override
  State<AdditionalInfo> createState() => _AdditionalInfoState();
}

class _AdditionalInfoState extends State<AdditionalInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedGender;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppUiConstants.paddingOutsideForm,
      child: Center(
        child: Form(
          key: _formKey,
          child: FieldFormContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    // Date of birth
                    style: TextStyle(color: Colors.white,fontSize: 16),
                    readOnly: true,
                    controller: _dateController,
                    validator: (value) => AuthService.instance.validateFields('dateOfBirth', value),
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
                    validator: (value) => AuthService.instance.validateFields("gender",value),
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
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                  // Weight
                  TextFormField(
                    controller: _weightController,
                    validator: (value) => AuthService.instance.validateFields('weight', value),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: "Weight",
                      hintText: "Weight in kg",
                      prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.white),
                    ),
                  ),
                  SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                  // Height
                  TextFormField(
                    controller: _heightController,
                    validator: (value) => AuthService.instance.validateFields('height', value),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: "Height",
                      hintText: "Height in cm",
                      prefixIcon: Icon(Icons.height, color: AppColors.white),
                    ),
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
                            "weight": _weightController.text,
                            "height": _heightController.text,
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
