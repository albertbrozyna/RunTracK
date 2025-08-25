import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/l10n/app_localizations.dart';

class StartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StartPageState();
  }
}

class StartPageState extends State<StartPage> {
  void handleLoginButton(BuildContext context) {
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
            image: AssetImage("assets/background-start.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Text(
                AppLocalizations.of(context)!.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // change if needed
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                  ],
                ),
              ),

              const Spacer(), // Push logo section to the middle
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
                    Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                  ],
                ),
              ),

              const Spacer(),

              // Sized box to fill the screen
              SizedBox(
                width: double.infinity,
                height: 60,
                child: CustomButton(
                  text: "Login",
                  onPressed: () => handleLoginButton(context),
                  gradientColors: [
                    Color(0xFFFF6F00), // Orange
                    Color(0xFFD9AA64), // Peach
                    Color(0xFFD0CDCA), // Peach
                  ],
                  textSize: 20,
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 15,
              ),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: CustomButton(
                  text: "No account? Join our community",
                  onPressed: () => handleRegisterButton(context),
                  textSize: 20,
                  gradientColors: [
                    Color(0xFFFF8C00), // Vivid Orange
                    Color(0xFFFFD180), // Soft Amber
                    Color(0xFF64B5F6), // Light Sky Blue
                  ],
                ),
              ),
              SizedBox(height: 60,)
            ],
          ),
        ),
      ),
    );
  }
}
