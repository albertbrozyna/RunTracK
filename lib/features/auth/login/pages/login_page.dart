import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:run_track/common/utils/validators.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/home/home_page.dart';
import 'package:run_track/models/user.dart' as model;
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/text_styles.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../../common/utils/app_data.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    UserService.signOutUser();
  }

  void handleLogin() {
    if (!isEmailValid(_emailController.text.trim())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Given email is incorrect")));
      return;
    }

    loginUser();
  }

  Future<void> loginUser() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user?.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Incorrect email or password, try again."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      AppData.currentUser = await UserService.fetchUser(
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (AppData.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User don't exists."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // TODO UI
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logged in successfully")));
      }

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log in", style: AppTextStyles.PageHeaderTextStyle),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/appBg4.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -50),
            child: SingleChildScrollView(
              child: Padding(
                padding: AppUiConstants.paddingOutsideForm,
                child: Column(
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsetsGeometry.only(bottom: 0),
                      child: Image.asset(
                        "assets/runtrack-app-icon-round.png",
                        width: 300,
                      ),
                    ),
                    // App name
                    Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 15),
                      child: Text(
                        "RunTracK",
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Form
                    Form(
                      child: Container(
                        padding: AppUiConstants.paddingInsideForm,
                        decoration: BoxDecoration(
                          color: AppColors.textFieldsBackground,
                          borderRadius: AppUiConstants.borderRadiusForm,
                          boxShadow: AppUiConstants.boxShadowForm,
                        ),
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(Icons.email),
                                border: AppUiConstants.borderTextFields,
                                errorBorder: AppUiConstants.errorBorderTextFields,
                                enabledBorder: AppUiConstants.enabledBorderTextFields,
                                focusedBorder: AppUiConstants.focusedBorderTextFields,
                              ),
                            ),
                            SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                            TextFormField(
                              controller: _passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: _isPasswordHidden,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: Icon(Icons.password),
                                border: AppUiConstants.borderTextFields,
                                errorBorder: AppUiConstants.errorBorderTextFields,
                                enabledBorder: AppUiConstants.enabledBorderTextFields,
                                focusedBorder: AppUiConstants.focusedBorderTextFields,
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
                              ),
                            ),
                            SizedBox(height: AppUiConstants.verticalSpacingButtons),
                            // Login
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: CustomButton(
                                text: "Login",
                                onPressed: () => handleLogin(),
                                textSize: 20,

                              ),
                            ),
                          ],
                        ),
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
