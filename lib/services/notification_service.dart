import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/constants/firestore_names.dart';
import 'package:run_track/models/notification.dart';

class NotificationService {
  static DocumentSnapshot? lastFetchedNotificationDoc;

  /// Save notification to database
  static Future<bool> saveNotification(AppNotification notification) async {
    if (notification.uid.isEmpty) {
      return false;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.notifications).doc();

      final newNotification = AppNotification(
        notificationId: docRef.id,
        uid: notification.uid,
        title: notification.title,
        createdAt: notification.createdAt,
        seen: notification.seen,
        type: notification.type,
      );

      await docRef.set(newNotification.toMap());
      return true;
    } catch (e) {
      print('Error saving notification: $e');
      return false;
    }
  }

  /// Fetch last page of user notifications only for one user
  static Future<List<AppNotification>> fetchUserNotifications({required String uid, int limit = 10, DocumentSnapshot? lastDocument}) async {
    if (uid.isEmpty) {
      return [];
    }

    final List<AppNotification> allNotifications = [];
    Query databaseQuery = FirebaseFirestore.instance
        .collection(FirestoreCollections.notifications)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      databaseQuery = databaseQuery.startAfterDocument(lastDocument);
    }

    final snapshot = await databaseQuery.get();

    if (snapshot.docs.isNotEmpty) {
      lastFetchedNotificationDoc = snapshot.docs.last;

      allNotifications.addAll(snapshot.docs.map((doc) => AppNotification.fromMap(doc.data() as Map<String, dynamic>)));
    }

    allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allNotifications;
  }
}
