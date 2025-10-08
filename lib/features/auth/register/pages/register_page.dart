import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/app_constants.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../../common/utils/validators.dart';
import '../../models/auth_response.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;

  bool _isPasswordHidden = true;
  bool _isPasswordRepeatHidden = true;


  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  // Method to check password complexity
  bool checkPasswordComplexity(String password) {
    // Minimum 8 characters
    // if (password.length < 7) return false;
    // // At least one uppercase letter
    // if (!password.contains(RegExp(r'[A-Z]'))) return false;
    // // At least one lowercase letter
    // if (!password.contains(RegExp(r'[a-z]'))) return false;
    // // At least one digit
    // if (!password.contains(RegExp(r'[0-9]'))) return false;
    // // At least one special character
    // if (!password.contains(RegExp(r'[!@#\$&*~%^]'))) return false;

    return true;
  }

  /// Unified field validator using switch-case
  String? validateFields(String fieldName, String? value) {
    switch (fieldName) {
      case 'firstName':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your first name';
        }
        if (value.length < 2) {
          return 'First name must be at least 2 characters long';
        }
        break;
      case 'lastName':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your last name';
        }
        break;
      case 'email':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address';
        }
        if (!isEmailValid(value.trim())) {
          return 'Invalid email format';
        }
        break;
      case 'password':
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a password';
        }
        if (!checkPasswordComplexity(value.trim())) {
          return 'Password must have at least 8 chars, one uppercase, lowercase, digit, and special character';
        }
        break;
      case 'repeatPassword':
        if (value == null || value.trim().isEmpty) {
          return 'Please repeat your password';
        }
        if (value.trim() != _passwordController.text.trim()) {
          return 'Passwords do not match';
        }
        break;
      case 'gender':
        if (_selectedGender == null || _selectedGender!.isEmpty) {
          return 'Please select your gender';
        }
        break;
      case 'dateOfBirth':
        if (value == null || value.trim().isEmpty) {
          return 'Please select your date of birth';
        }
        break;
      default:
        return null;
    }
    return null;
  }

  /// Handle register button click
  void handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool error = false;
    AuthResponse? result = await UserService.createUserInFirebaseAuth(
      _emailController.text,
      _passwordController.text,
    );

    if (result.message == null || result.message != "User created") {
      error = true;
    }


    if (!error) {
      String? resultMessage = await UserService.createUserInFirestore(
        result.userCredential!.user!.uid,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _emailController.text.trim(),
        _selectedGender!,
        DateTime.parse(_dateController.text.trim()),
      );
      if (resultMessage != "User created") {
        error = true;
      }
    }
    if (error) {
      User? firebaseUser = result.userCredential?.user;
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Log in again if there is a this err code
            await firebaseUser.reauthenticateWithCredential(
              EmailAuthProvider.credential(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              ),
            );
            await firebaseUser.delete();
          }
        }
      }

      if (mounted) {
        AppUtils.showMessage(context, "Register failed!", isError: true);
      }
    } else {
      // Success
      if (mounted) {
        AppUtils.showMessage(context, "Registered successfully!");
        FirebaseAuth.instance.signOut();
      }
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Sign up", style: AppTextStyles.PageHeaderTextStyle),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-start.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.formBackgroundOverlay,
                        borderRadius: AppUiConstants.borderRadiusForm,
                        boxShadow: AppUiConstants.boxShadowForm,
                      ),
                      child: Column(
                        children: [
                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            validator: (value) =>
                                validateFields('firstName', value),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "First Name",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Last name
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) =>
                                validateFields('lastName', value),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "Last name",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          SizedBox(
                            height: AppUiConstants.verticalSpacingTextFields,
                          ),
                          // Date of birth
                          TextFormField(
                            controller: _dateController,
                            validator: (value) =>
                                validateFields('dateOfBirth', value),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Date of Birth",
                              prefixIcon: Icon(Icons.calendar_today),

                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              contentPadding:
                                  AppUiConstants.contentPaddingTextFields,
                            ),
                            onTap: () async {
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
                          SizedBox(
                            height: AppUiConstants.verticalSpacingTextFields,
                          ),
                          // Gender
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: InputDecoration(
                              labelText: "Gender",
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              contentPadding:
                                  AppUiConstants.contentPaddingTextFields,
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
                          SizedBox(
                            height: AppUiConstants.verticalSpacingTextFields,
                          ),
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            validator: (value) =>
                                validateFields('email', value),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              enabledBorder: AppUiConstants.enabledBorderTextfields,
                              focusedBorder: AppUiConstants.focusedBorderTextfields,
                              contentPadding:
                                  AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          SizedBox(height:AppUiConstants.verticalSpacingTextFields),
                          TextFormField(
                            controller: _passwordController,
                            validator: (value) =>
                                validateFields('password', value),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordHidden,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.password),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              enabledBorder:
                                  AppUiConstants.enabledBorderTextfields,
                              focusedBorder:
                                  AppUiConstants.focusedBorderTextfields,
                              contentPadding:
                                  AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          SizedBox(
                            height: AppUiConstants.verticalSpacingTextFields,
                          ),
                          // Repeat password
                          TextFormField(
                            controller: _repeatPasswordController,
                            validator: (value) =>
                                validateFields('repeatPassword', value),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordRepeatHidden,
                            decoration: InputDecoration(
                              labelText: "Repeat password",
                              prefixIcon: Icon(Icons.password),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordRepeatHidden =
                                        !_isPasswordRepeatHidden;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordRepeatHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    AppUiConstants.borderRadiusTextFields,
                              ),
                              enabledBorder:
                                  AppUiConstants.enabledBorderTextfields,
                              focusedBorder:
                                  AppUiConstants.focusedBorderTextfields,
                              contentPadding:
                                  AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          // Register button
                          SizedBox(
                            height: AppUiConstants.verticalSpacingButtons,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: CustomButton(
                              text: "Register",
                              onPressed: handleRegister,
                              textSize: 20,
                              gradientColors: [
                                Color(0xFFFF8C00),
                                Color(0xFFFFD180),
                                Color(0xFF64B5F6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
