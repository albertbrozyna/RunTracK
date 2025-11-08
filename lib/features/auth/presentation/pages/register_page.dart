import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../../models/auth_response.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;

  bool _isPasswordHidden = true;
  bool _isPasswordRepeatHidden = true;

  @override
  void dispose() {
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

        DateTime? date = DateTime.tryParse(value.trim());
        if (date == null) {
          return 'Invalid date format';
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
    AuthResponse? result = await UserService.createUserInFirebaseAuth(_emailController.text, _passwordController.text);

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
              EmailAuthProvider.credential(email: _emailController.text.trim(), password: _passwordController.text.trim()),
            );
            await firebaseUser.delete();
          }
        }
      }

      if (mounted) {
        AppUtils.showMessage(context, "Register failed : ${result.message}", messageType: MessageType.error);
      }
    } else {
      // Success
      if (mounted) {
        AppUtils.showMessage(context, "Registered successfully!",messageType: MessageType.success);
        FirebaseAuth.instance.signOut();
      }

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Sign up"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/appBg6.jpg"), fit: BoxFit.cover),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    PageContainer(
                      child: Column(
                        children: [
                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            validator: (value) => validateFields('firstName', value),
                            keyboardType: TextInputType.text,
                            style: AppUiConstants.textStyleTextFields,
                            decoration: InputDecoration(
                              labelText: "First Name",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              prefixIcon: Icon(Icons.person,color: AppColors.white,),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Last name
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) => validateFields('lastName', value),
                            keyboardType: TextInputType.text,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Last name",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedErrorBorderTextFields,
                              prefixIcon: Icon(Icons.person,color: AppColors.white,),
                              border: OutlineInputBorder(borderRadius: AppUiConstants.borderRadiusTextFields),
                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Date of birth
                          TextFormField(
                            controller: _dateController,
                            validator: (value) => validateFields('dateOfBirth', value),
                            readOnly: true,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Date of Birth",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              prefixIcon: Icon(Icons.calendar_today,color: AppColors.white,),
                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                            onTap: () async {
                              AppUtils.pickDate(context, DateTime(1900), DateTime.now(), _dateController, true);
                            },
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Gender
                          DropdownButtonFormField<String>(
                            dropdownColor: AppColors.primary,
                            initialValue: _selectedGender,
                            style: AppUiConstants.textStyleTextFields,

                            decoration: InputDecoration(
                              labelText: "Gender",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedErrorBorderTextFields,
                              prefixIcon: Icon(Icons.person_outline,color: AppColors.white,),
                              border: OutlineInputBorder(borderRadius: AppUiConstants.borderRadiusTextFields),
                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                            items: AppConstants.genders.map((String gender) {
                              return DropdownMenuItem<String>(value: gender, child: Text(gender));
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            validator: (value) => validateFields('email', value),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedErrorBorderTextFields,
                              prefixIcon: Icon(Icons.email,color: AppColors.white,),
                              border: OutlineInputBorder(borderRadius: AppUiConstants.borderRadiusTextFields),

                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          TextFormField(
                            controller: _passwordController,
                            validator: (value) => validateFields('password', value),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordHidden,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedErrorBorderTextFields,
                              prefixIcon: Icon(Icons.password,color: AppColors.white,),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                                icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility,color: AppColors.white,),
                              ),
                              border: OutlineInputBorder(borderRadius: AppUiConstants.borderRadiusTextFields),

                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Repeat password
                          TextFormField(
                            controller: _repeatPasswordController,
                            validator: (value) => validateFields('repeatPassword', value),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordRepeatHidden,
                            style: TextStyle(color: AppColors.white),

                            decoration: InputDecoration(
                              labelText: "Repeat password",
                              labelStyle: AppUiConstants.labelStyleTextFields,
                              enabledBorder: AppUiConstants.enabledBorderTextFields,
                              focusedBorder: AppUiConstants.focusedBorderTextFields,
                              errorBorder: AppUiConstants.errorBorderTextFields,
                              focusedErrorBorder: AppUiConstants.focusedErrorBorderTextFields,
                              prefixIcon: Icon(Icons.password,color: AppColors.white,),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordRepeatHidden = !_isPasswordRepeatHidden;
                                  });
                                },
                                icon: Icon(_isPasswordRepeatHidden ? Icons.visibility_off : Icons.visibility,color: AppColors.white,),
                              ),
                              border: OutlineInputBorder(borderRadius: AppUiConstants.borderRadiusTextFields),
                              contentPadding: AppUiConstants.contentPaddingTextFields,
                            ),
                          ),
                          // Register button
                          SizedBox(height: AppUiConstants.verticalSpacingButtons),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: CustomButton(text: "Register", onPressed: handleRegister, textSize: 20),
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
