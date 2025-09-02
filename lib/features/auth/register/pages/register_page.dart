import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/common/widgets/custom_button.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';

import '../../../../common/utils/validators.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _isPasswordHidden = true;
  bool _isPasswordRepeatHidden = true;

  // Method to check password complexity
  bool checkPasswordComplexity(String password) {
    // Minimum 8 characters
    if (password.length < 7) return false;

    // At least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // At least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // At least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // At least one special character
    if (!password.contains(RegExp(r'[!@#\$&*~%^]'))) return false;

    return true;
  }

  void handleRegister() {
    if (_passwordController.text.trim() !=
        _repeatPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
    }
    if (!checkPasswordComplexity(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password must be at least 8 chars, include uppercase, lowercase, number, and special char.",
          ),
        ),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select your gender.")));
      return;
    }

    if (!isEmailValid(_emailController.text.trim())) {
      // TODO make a good communicates
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Given email is incorrect")));
      return;
    }

    createUserWithEmailAndPassword();

    // Successfully register
    if (FirebaseAuth.instance.currentUser != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registered successfully!")));
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // Create a new user
      try {
        final data = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .set({
              "firstName": _firstNameController.text.trim(),
              "lastName": _lastNameController.text.trim(),
              "email": _emailController.text.trim(),
              "dateOfBirth": _dateController.text.trim(),
              "gender": _selectedGender,
              "activities": AppUtils.getDefaultActivities(),
              "friends": List<String>.empty,
            });
      } catch (firestoreError) {
        await userCredential.user!.delete();
      }

      // Sign out user after registration, user needs to log in
      FirebaseAuth.instance.signOut();
      // Navigate to login screen after registration
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          // TODO I think that it is to check and fix
          // Remove all routes
          (Route<dynamic> route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      // TODO Better communicates
      print("Auth error ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign up")),
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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
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
                      // First Name
                      TextField(
                        controller: _firstNameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "First Name",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Last name
                      TextField(
                        controller: _lastNameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Last name",
                          prefixIcon: Icon(Icons.person),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Date of birth
                      TextField(
                        controller: _dateController,
                        readOnly: true, // Makes the field non-editable
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          prefixIcon: Icon(Icons.calendar_today),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            String formattedDate =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            _dateController.text = formattedDate;
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      // Gender
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: "Gender",
                          prefixIcon: Icon(Icons.person_outline),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        items: _genders.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _repeatPasswordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: _isPasswordRepeatHidden,
                        decoration: InputDecoration(
                          labelText: "Repeat password",
                          prefixIcon: Icon(Icons.password),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordRepeatHidden =
                                    !_isPasswordRepeatHidden;
                              });
                            },
                            icon: Icon(
                              _isPasswordRepeatHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      // Register button
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: CustomButton(
                          text: "Register",
                          onPressed: handleRegister,
                          textSize: 20,
                          gradientColors: [
                            Color(0xFFFF8C00), // Vivid Orange
                            Color(0xFFFFD180), // Soft Amber
                            Color(0xFF64B5F6), // Light Sky Blue
                          ],
                        ),
                      ),
                    ],
                  ), // closes Column
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
