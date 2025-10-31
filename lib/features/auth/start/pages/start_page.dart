import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/config/assets/app_images.dart';
import 'package:run_track/config/routes/app_routes.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/models/sign_in_result.dart';
import 'package:run_track/services/google_service.dart';
import 'package:run_track/models/user.dart' as model;
import 'package:run_track/services/user_service.dart';
import '../../../../common/enums/sign_in_status.dart';
import '../../../../common/utils/app_data.dart';
import '../../../../config/assets/app_icons.dart';
import '../../../../theme/ui_constants.dart';
import '../widgets/additional_info_form.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return StartPageState();
  }
}

class StartPageState extends State<StartPage> {
  /// Handle sign in with google
  Future<void> handleSignInWithGoogle() async {
    AppData.googleLogin = true;
    SignInResult result = await GoogleService.signInWithGoogle();

    if (result.status == SignInStatus.success) {
      // User exist in database so we log in
      AppData.googleLogin = false;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        });
      }
      return;
    } else if (result.status == SignInStatus.userDoesNotExists) {
      model.User? newUser = result.user;

      if (newUser == null) {
        AppData.googleLogin = false;
        GoogleService.signOutFromGoogle();
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
            AppData.googleLogin = false;
            AppUtils.showMessage(context, "Registered successfully!");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamedAndRemoveUntil(context,AppRoutes.home,(route) => false);
            });
          } else {
            AppData.googleLogin = false;
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void handleRegisterButton(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageContainer(
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
