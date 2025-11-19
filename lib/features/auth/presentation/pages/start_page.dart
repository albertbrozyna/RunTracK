import 'package:flutter/material.dart';
import 'package:run_track/features/auth/data/services/auth_service.dart';

import '../../../../app/config/app_icons.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/sign_in_status.dart';
import '../../../../core/models/sign_in_result.dart';
import '../../../../core/models/user.dart' as model show User;
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/page_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/additional_info_form.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StatefulWidget> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  /// Handle sign in with google
  Future<void> handleSignInWithGoogle() async {
    SignInResult result = await AuthService.instance.signInWithGoogle();

    if (result.status == SignInStatus.success) {
      // User exist in database so we log in
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, AppRoutes.appInitializer);
        });
        setState(() {

        });
      }
      return;
    } else if (result.status == SignInStatus.userDoesNotExists) {
      model.User? newUser = result.user;

      if (newUser == null) {
        await AuthService.instance.signOutUser();
        return;
      }

      // If we are logging for the first time, show modal with dateOfBirth and gender
      if (mounted) {
        final additionalData = await showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: AdditionalInfo(),
          ),
        );

        if(additionalData == null){
          return;
        }

        newUser.dateOfBirth = DateTime.parse(additionalData["dob"]!.trim());
        newUser.gender = additionalData["gender"]!;
        String message = await UserService.createUserInFirestore(
          newUser.uid,
          newUser.firstName,
          newUser.lastName,
          newUser.email,
          newUser.gender!,
          newUser.dateOfBirth!,
        );
        if (mounted) {
          if (message == "User created") {
            AppUtils.showMessage(context, "Registered successfully!");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, AppRoutes.appInitializer);
            });
            setState(() {

            });
          } else {
            AppUtils.showMessage(context, "Register failed!", messageType: MessageType.error);
          }
        }
      }
    } else if (result.status == SignInStatus.failed) {
      if (mounted && result.errorMessage != null) {
        AppUtils.showMessage(context, result.errorMessage!, messageType: MessageType.error);
      }
      return;
    }
  }

  void handleLoginButton(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void handleRegisterButton(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
          body: PageContainer(
          darken: false,
          assetPath: AppImages.appBg4,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsetsGeometry.only(top: 14),
                                  child: Text(
                                    AppLocalizations.of(context)!.appName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2))],
                                    ),
                                  ),
                                ),
                      
                                Image.asset(
                                  AppImages.runtrackAppIcon,
                                  width: 300,
                                ),
                      
                                // Text under the logo
                                Text(
                                  AppLocalizations.of(context)!.startPageWelcomeMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // change if needed
                                    shadows: [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2))],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Title
                          Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 2,
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onPressed: () => handleSignInWithGoogle(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Image.asset(AppIcons.googleIcon, height: 40, width: 40),
                                      SizedBox(width: 10),
                                      Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: AppUiConstants.verticalSpacingButtons),
                              CustomButton(text: "Login", onPressed: () => handleLoginButton(context)),
                              SizedBox(height: AppUiConstants.verticalSpacingButtons),
                              CustomButton(text: "No account? Join our community", onPressed: () => handleRegisterButton(context)),
                              SizedBox(height: 50,),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
            ),
      );
  }
}
