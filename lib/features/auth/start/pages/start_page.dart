import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';
import 'package:run_track/features/auth/register/pages/register_page.dart';

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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/backgrounds/background-start.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
             CustomButton(text: "Login", onPressed: () => handleLoginButton(context)),
              CustomButton(text: "No account? Join our community", onPressed: () => handleRegisterButton(context)),
            ],
          ),
        ),
      ),
    );
  }
}
