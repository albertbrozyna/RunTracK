import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';
import 'package:run_track/l10n/app_localizations.dart';
import 'package:run_track/models/sign_in_result.dart';
import 'package:run_track/services/google_service.dart';
import 'package:run_track/models/user.dart' as model;
import 'package:run_track/services/user_service.dart';
import '../../../../common/enums/sign_in_status.dart';
import '../../../../common/utils/app_data.dart';
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

    if (result.status == SignInStatus.success) {  // User exist in database so we log in
      AppData.googleLogin = false;
      if(mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
      }
      return;
    } else if (result.status == SignInStatus.userDoesNotExists) {
      model.User? newUser = result.user;

      if (newUser == null) {
        // TODO SIGN OUT FROM GOOGLE
        AppData.googleLogin = false;
        return;
      }

      // If we are logging for the first time, show modal with dateOfBirth and gender
      if (mounted) {
        final additionalData = await showDialog<Map<String, String>>(

          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AdditionalInfo(),
            ),
          ),
        );
        newUser.dateOfBirth = DateTime.parse(additionalData!["dob"]!);
        newUser.gender = additionalData["gender"]!;
        String message = await UserService.createUserInFirestore(
          newUser.uid,
          newUser.firstName,
          newUser.lastName,
          newUser.email!,
          newUser.gender!,
          newUser.dateOfBirth!,
        );
        if(mounted){
          if(message == "User created"){
            AppData.googleLogin = false;
            AppUtils.showMessage(context, "Registered successfully!");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
          }else{
            AppData.googleLogin = false;
            AppUtils.showMessage(context, "Register failed!",isError: true);
          }
        }
      }
    } else if (result.status == SignInStatus.failed) {
      if (mounted && result.errorMessage != null) {
        AppUtils.showMessage(context, result.errorMessage!, isError: true);
      }
      return;
    }
  }

  void handleLoginButton(BuildContext context) {
    // TODO change it to name
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void handleRegisterButton(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Padding(
                padding: EdgeInsetsGeometry.only(top: 14),
                child: Text(
                  AppLocalizations.of(context)!.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // change if needed
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              // Push logo section to the middle
              // Logo
              Image.asset(
                "assets/runtrack-app-icon-round.png", // your logo path
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
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Sized box to fill the screen
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => handleSignInWithGoogle(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Image.asset(
                        'assets/google-icon.png',
                        height: 40,
                        width: 40,
                      ),
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
              SizedBox(
                width: double.infinity,
                height: 60,
                child: CustomButton(
                  text: "Login",
                  onPressed: () => handleLoginButton(context),

                  textSize: 20,
                ),
              ),
              SizedBox(height: AppUiConstants.verticalSpacingButtons),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: CustomButton(
                  text: "No account? Join our community",
                  onPressed: () => handleRegisterButton(context),
                  textSize: 20,

                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
