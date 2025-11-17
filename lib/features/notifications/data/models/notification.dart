enum NotificationType { inviteCompetition, inviteFriends }

class AppNotification {
  String notificationId;
  String uid; // User uid
  String objectId; // By object id i mean activity or user that sens us action
  String title; // Title of notification
  NotificationType type;
  DateTime createdAt;
  bool seen;

  AppNotification({
    required this.notificationId,
    required this.uid,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.seen,
    required this.objectId
  });

  /// Convert Notification to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'uid': uid,
      'title': title,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'seen': seen,
      'objectId': objectId,
    };
  }

  /// Create Notification from Firestore map
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      notificationId: map['notificationId'] ?? '',
      uid: map['uid'] ?? '',
      objectId: map['objectId'] ?? '',
      title: map['title'] ?? '',
      type: NotificationType.values.firstWhere((e) => e.name == map['type'], orElse: () => NotificationType.inviteCompetition),
      createdAt: map['createdAt'] is DateTime ? map['createdAt'] : DateTime.parse(map['createdAt']),
      seen: map['seen'] ?? false,
    );
  }
}
