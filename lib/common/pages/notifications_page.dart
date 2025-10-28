import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/notification_tile.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/models/notification.dart';

import '../../services/notification_service.dart';
import '../../theme/ui_constants.dart';
import '../widgets/no_items_msg.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  bool _hasMore = true;
  int _limit = 20;
  ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastPageNotifications;
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {}

  void initializeAsync() {
    _loadMyNotifications();
  }

  Future<void> _loadMyNotifications() async {
    if (_isLoading || !_hasMore) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final activities = await NotificationService.fetchUserNotifications(
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      limit: _limit,
      lastDocument: _lastPageNotifications,
    );

    setState(() {
      _notifications.addAll(activities);
      _lastPageNotifications = activities.isNotEmpty ? NotificationService.lastFetchedNotificationDoc : null;
      _isLoading = false;
      if (activities.length < _limit) {
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: PageContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: _notifications.isEmpty
                    ? NoItemsMsg(textMessage: "No notifications found")
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _notifications.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _notifications.length) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final notification = _notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                            child: NotificationTile(key: ValueKey(notification.notificationId), notification: notification),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
