import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/app_images.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../data/models/notification.dart';
import '../../data/services/notification_service.dart';
import '../../../../core/widgets/no_items_msg.dart';
import '../widgets/notification_tile.dart';
import '../../../../core/widgets/page_container.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastPageNotifications;
  final List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void initialize() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && _hasMore) {
        _loadMyNotifications();
      }
    });

    _loadMyNotifications();
  }


  Future<void> _loadMyNotifications() async {
    if (_isLoading || !_hasMore) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationFetchResult = await NotificationService.fetchUserNotifications(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: _limit,
        lastDocument: _lastPageNotifications,
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(notificationFetchResult.notifications);
          _lastPageNotifications = notificationFetchResult.lastDocument;

          if (notificationFetchResult.notifications.length < _limit) {
            _hasMore = false;
          }

          _isLoading = false;
        });
      }

    } catch (e) {
      print("Error loading notifications: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Widget buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_isLoading && _notifications.isEmpty) {
      return NoItemsMsg(textMessage: "No notifications found");
    }

    return ListView.builder(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: PageContainer(assetPath:AppImages.appBg4,child: buildContent()),
    );
  }
}
