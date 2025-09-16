import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/validators.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/home/home_page.dart';
import 'package:run_track/models/user.dart' as model;

import '../../../../common/utils/app_data.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleLogin() {
    if (!isEmailValid(_emailController.text.trim())) {
      // TODO make a good communicates
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Given email is incorrect")));
      return;
    }

    loginUser();
  }

  Future<void> loginUser() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user?.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Incorrect email or password, try again."),
          backgroundColor: Colors.red,
        ));
        return;
      }

      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user?.uid)
          .get();

      if (!userData.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User data not found.")));
        return;
      }

      AppData.currentUser = new model.User(
        uid: FirebaseAuth.instance.currentUser!.uid,
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        activityNames: List<String>.from(userData['activityNames'] ?? []),
        activities: [],
        friendsUids: List<String>.from(userData['friends'] ?? []),
        email: userData['email'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login successful!"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log in")),
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

        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(16), // Add padding inside the box
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                // Background color with opacity
                borderRadius: BorderRadius.circular(16),
                // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // Shadow color
                    blurRadius: 10, // How blurry the shadow is
                    offset: Offset(0, 4), // Position of the shadow
                  ),
                ],
              ),
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
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  // Break between inputs
                  SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: _isPasswordHidden,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.password),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                        icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Login
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: CustomButton(
                      text: "Login",
                      onPressed: () => handleLogin(),
                      textSize: 20,
                      gradientColors: [
                        Color(0xFFFF8C00), // Vivid Orange
                        Color(0xFFFFD180), // Soft Amber
                        Color(0xFF64B5F6), // Light Sky Blue
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
