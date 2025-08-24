import 'package:flutter/material.dart';
import 'package:inzynierka/features/auth/login/pages/login_page.dart';
import 'package:inzynierka/features/auth/register/pages/register_page.dart';


class StartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StartPageState();
  }
}

class StartPageState extends State<StartPage> {
  void handleLoginButton(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void handleRegisterButton(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => RegisterPage()));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Padding(padding: EdgeInsets.all(16), child: Column(
      children: [
        ElevatedButton(onPressed: () => handleLoginButton(context), child: Text("Login")),
        ElevatedButton(onPressed: () => handleRegisterButton(context), child: Text("Register")),
      ],
    )
    ));
  }

}