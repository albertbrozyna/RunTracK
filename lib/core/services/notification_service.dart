import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_track/core/constants/firestore_names.dart';

import '../models/notification.dart';

class NotificationFetchResult {
  final List<AppNotification> notifications;
  final DocumentSnapshot? lastDocument;

  NotificationFetchResult({
    required this.notifications,
    this.lastDocument,
  });
}

class NotificationService {

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
  static Future<NotificationFetchResult> fetchUserNotifications({required String uid, int limit = 10, DocumentSnapshot? lastDocument}) async {
    if (uid.isEmpty) {
      return NotificationFetchResult(notifications: [], lastDocument: null);
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
    DocumentSnapshot? newLastDocument;

    if (snapshot.docs.isNotEmpty) {
      newLastDocument = snapshot.docs.last;
      allNotifications.addAll(snapshot.docs.map((doc) => AppNotification.fromMap(doc.data() as Map<String, dynamic>)));
    }

    return NotificationFetchResult(
      notifications: allNotifications,
      lastDocument: newLastDocument,
    );
  }
}
