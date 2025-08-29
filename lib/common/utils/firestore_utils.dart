import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_data.dart'; // your global AppData class

/// Fetch a Firestore user ID by email
Future<String?> fetchUserIdByEmail(String email) async {
  if (email.isEmpty) return null;

  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    final userId = query.docs.first.id;
    return userId;
  } else {
    return null;
  }
}

/// Fetch current authenticated user and store globally
Future<void> fetchCurrentUserAndSave() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user?.email != null) {
    final userId = await fetchUserIdByEmail(user!.email!);
    if (userId != null) {
      AppData.currentUserId = userId; // store globally
      print('Current user ID saved globally: ${AppData.currentUserId}');
    }
  } else {
    print('No authenticated user found');
  }
}
