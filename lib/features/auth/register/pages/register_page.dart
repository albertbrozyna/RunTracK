import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/features/auth/login/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];


  void handleLoginButton(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
    }
    if (!checkPasswordComplexity(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 8 chars, include uppercase, lowercase, number, and special char.")),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select your gender.")),
      );
      return;
    }

    createUserWithEmailAndPassword();
  }


  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );
      // Create a new user
      final data = await FirebaseFirestore.instance.collection("users").add({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "dateOfBirth": _dateController.text.trim(),
        "gender":_selectedGender
      });
    } on FirebaseAuthException catch (e) {
      print("Auth error ${e.message}");
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // First Name
              TextField(
                // Bounding with controller
                controller: _firstNameController,
                // What keyboard to show
                keyboardType: TextInputType.text,
                // Decoration of the input
                decoration: InputDecoration(
                  labelText: "First Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              // Last name
              TextField(
                // Bounding with controller
                controller: _lastNameController,
                // What keyboard to show
                keyboardType: TextInputType.text,
                // Decoration of the input
                decoration: InputDecoration(
                  labelText: "last name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
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
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900), // Earliest selectable date
                    lastDate: DateTime.now(), // Latest selectable date
                  );
                  if (pickedDate != null) {
                    String formattedDate = "${pickedDate.day}/${pickedDate
                        .month}/${pickedDate.year}";
                    _dateController.text = formattedDate;
                  }
                },
              ),
              // Gender

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: "Gender",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
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
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.password),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              TextField(
                controller: _repeatPasswordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.password),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              // Login
              ElevatedButton(
                onPressed: handleRegister,
                child: Text("Register"),
              ),
              TextButton(
                onPressed: () => handleLoginButton(context),
                child: Text("Log in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
