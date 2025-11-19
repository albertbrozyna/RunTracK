import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/auth/presentation/widgets/field_form.dart';
import 'package:run_track/features/auth/utils/validators.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/message_type.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/custom_button.dart';


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
  }

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

      AppData.instance.currentUser = await UserService.fetchUser(FirebaseAuth.instance.currentUser!.uid);
      if (AppData.instance.currentUser == null) {
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
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.appInitializer,(route) => false);
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
        child: PageContainer(
          darken: false,
          assetPath: AppImages.appBg4,
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
                        child: Image.asset(AppImages.runtrackAppIcon, width: 300),
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
                        child: FieldFormContainer(
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
