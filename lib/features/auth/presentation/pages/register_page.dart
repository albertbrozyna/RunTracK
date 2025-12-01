import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';
import 'package:run_track/features/auth/presentation/widgets/field_form.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../../data/models/auth_response.dart';

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
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
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
        double.parse(_weightController.text.trim()),
        int.parse(_heightController.text.trim()),
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
        AppUtils.showMessage(
          context,
          "Register failed : ${result.message}",
          messageType: MessageType.error,
        );
      }
    } else {
      try{
        if (result.userCredential?.user != null && !result.userCredential!.user!.emailVerified) {
          await result.userCredential?.user?.sendEmailVerification();
        }

        // Success
        if (mounted) {
          AppUtils.showMessage(context, "Registered successfully! Please verify your email.", messageType: MessageType.success);
        }

        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.verifyEmail);
          }
        });
      }catch(e){
        if (mounted) {
          AppUtils.showMessage(context, "Account created, but failed to send verification email: $e", messageType: MessageType.error);
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign up")),
      body: PageContainer(
        darken: false,
        assetPath: AppImages.appBg4,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    FieldFormContainer(
                      child: Column(
                        children: [
                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            validator: (value) => AuthService.instance.validateFields('firstName', value),
                            keyboardType: TextInputType.text,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "First Name",
                              prefixIcon: Icon(Icons.person, color: AppColors.white),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Last name
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) => AuthService.instance.validateFields('lastName', value),
                            keyboardType: TextInputType.text,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Last name",
                              prefixIcon: Icon(Icons.person, color: AppColors.white),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Date of birth
                          TextFormField(
                            controller: _dateController,
                            validator: (value) => AuthService.instance.validateFields('dateOfBirth', value),
                            readOnly: true,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Date of Birth",
                              prefixIcon: Icon(Icons.calendar_today, color: AppColors.white),
                            ),
                            onTap: () async {
                              AppUtils.pickDate(
                                context,
                                DateTime(1900),
                                DateTime.now(),
                                _dateController,
                                true,
                              );
                            },
                          ),

                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Gender
                          DropdownButtonFormField<String>(
                            dropdownColor: AppColors.primary,
                            initialValue: _selectedGender,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Gender",
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.white),
                            ),
                            items: AppConstants.genders.map((String gender) {
                              return DropdownMenuItem<String>(value: gender, child: Text(gender));
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                            validator: (value) => AuthService.instance.validateFields('gender', value),
                          ),
                          // Weight
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),

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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                          ),

                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            validator: (value) => AuthService.instance.validateFields('email', value),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email, color: AppColors.white),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          TextFormField(
                            controller: _passwordController,
                            validator: (value) => AuthService.instance.validateFields('password', value),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordHidden,
                            style: TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.password, color: AppColors.white),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                          // Repeat password
                          TextFormField(
                            controller: _repeatPasswordController,
                            validator: (value) => AuthService.instance.validateFields('repeatPassword', value,passwordController: _passwordController),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _isPasswordRepeatHidden,
                            style: TextStyle(color: AppColors.white),

                            decoration: InputDecoration(
                              labelText: "Repeat password",
                              prefixIcon: Icon(Icons.password, color: AppColors.white),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordRepeatHidden = !_isPasswordRepeatHidden;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordRepeatHidden ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          // Register button
                          SizedBox(height: AppUiConstants.verticalSpacingButtons),
                          CustomButton(text: "Register", onPressed: handleRegister, textSize: 20),
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
