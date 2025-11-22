import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/enums/message_type.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/custom_button.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/auth/presentation/widgets/field_form.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset() async {
    try {
      String email = _emailController.text.trim();

      if (email.isEmpty) {
        AppUtils.showMessage(context,"Please enter an email address",messageType: MessageType.error);
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if(!mounted)return;
      AppUtils.showMessage(context,"Password reset link sent! Check your email.",messageType: MessageType.error);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        msg = "No user found for that email.";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email format.";
      }
      if(!mounted) return;
      AppUtils.showMessage(context,msg,messageType: MessageType.error);
    } catch (e) {
      if(!mounted) return;
      AppUtils.showMessage(context,e.toString(),messageType: MessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: PageContainer(
        assetPath: AppImages.appBg4,
        child: Center(
          child: FieldFormContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your email and we will send you a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18,color: AppColors.white),
                ),
                const SizedBox(height:AppUiConstants.verticalSpacingTextFields),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email,color: AppColors.white,),
                  ),
                  style: TextStyle(color: AppColors.white),
                ),
            
                const SizedBox(height: AppUiConstants.verticalSpacingButtons),
                CustomButton(
                  text: "Reset Password",
                  onPressed: passwordReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}