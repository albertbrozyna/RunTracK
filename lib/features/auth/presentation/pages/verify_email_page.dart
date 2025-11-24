import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_images.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/core/widgets/custom_button.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/core/enums/message_type.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  void initialize() {
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Reload to check if email has been verified
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      if (mounted) {
        AppUtils.showMessage(
          context,
          "Email verified successfully!",
          messageType: MessageType.success,
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.appInitializer, (route) => false);
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) {
        AppUtils.showMessage(context, e.toString(), messageType: MessageType.error);
      }
    }
  }

  void handleCancel() async {
    timer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.start, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return const Scaffold(
        body: PageContainer(
          assetPath: AppImages.appBg4,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: PageContainer(
        assetPath: AppImages.appBg4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white),
                const SizedBox(height: AppUiConstants.verticalSpacingButtons),
                const Text(
                  "A verification email has been sent to your email address.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppUiConstants.verticalSpacingTextFields),
                const Text(
                  "Please click the link in the email to verify your account. Waiting for confirmation...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                ),
                const SizedBox(height: 30),

                CustomButton(
                  text: "Resend Email",
                  onPressed: canResendEmail ? sendVerificationEmail : () {},
                  backgroundColor: canResendEmail ? AppColors.third : Colors.grey,
                ),

                const SizedBox(height: AppUiConstants.verticalSpacingButtons),
                TextButton(
                  onPressed: handleCancel,
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
