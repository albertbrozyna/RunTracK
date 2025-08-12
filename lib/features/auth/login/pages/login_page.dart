import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleLogin(){
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    // TODO Api call
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log in")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email field
            TextField(
              // Bounding with controller
              controller: _emailController,
              // What keyboard to show
              keyboardType: TextInputType.emailAddress,
              // Decoration of the input
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                )
              ),
            ),
            // Break between inputs
            SizedBox(height: 16,),
            TextField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                )
              ),
            ),
            // Login
            ElevatedButton(
              onPressed: handleLogin,
              child: Text("Login"),
            )
          ],
        ),
      ),
    );
  }
}
