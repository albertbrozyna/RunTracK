import 'package:cloud_firestore/cloud_firestore.dart';

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
