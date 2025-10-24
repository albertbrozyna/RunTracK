import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/utils/validators.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/home/home_page.dart';
import 'package:run_track/services/user_service.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../../common/utils/app_data.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
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

  // TODO ADD VALIDATORS HERE

  void handleLogin() {
    if (!isEmailValid(_emailController.text.trim())) {
      AppUtils.showMessage(context, "Given email is incorrect", messageType: MessageType.error);
      return;
    }

    loginUser();
  }

  Future<void> loginUser() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user?.uid == null) {
        if (mounted) {
          AppUtils.showMessage(context, "Incorrect email or password, try again.", messageType: MessageType.info);
        }
        return;
      }

      AppData.currentUser = await UserService.fetchUser(FirebaseAuth.instance.currentUser!.uid);
      if (AppData.currentUser == null) {
        if (mounted) {
          AppUtils.showMessage(context, "User don't exists.", messageType: MessageType.info);
        }
        return;
      }

      if (mounted) {
        AppUtils.showMessage(context, "Logged in successfully!", messageType: MessageType.success);
      }

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
        }
      });
    } on FirebaseAuthException {
      if (mounted) {
        AppUtils.showMessage(context, "Incorrect email or password, try again.", messageType: MessageType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log in")),
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/appBg4.jpg"), fit: BoxFit.cover),
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
                        child: Image.asset("assets/runtrack-app-icon-round.png", width: 300),
                      ),
                      // App name
                      Padding(
                        padding: EdgeInsetsGeometry.only(bottom: 15),
                        child: Text(
                          "RunTracK",
                          style: TextStyle(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 34),
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
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppUiConstants.textStyleTextFields,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  hintText: "Enter your email",
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                              SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                              TextFormField(
                                controller: _passwordController,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _isPasswordHidden,
                                style: AppUiConstants.textStyleTextFields,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  hintText: "Enter your password",
                                  prefixIcon: Icon(Icons.password),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordHidden = !_isPasswordHidden;
                                      });
                                    },
                                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppUiConstants.verticalSpacingButtons),
                              CustomButton(text: "Login", onPressed: () => handleLogin()),
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
      ),
    );
  }
}
