import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/core/constants/firestore_collections.dart';
import 'package:run_track/core/enums/user_mode.dart';
import 'package:run_track/core/services/user_service.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
import 'package:run_track/features/competitions/data/services/competition_service.dart';
import 'package:run_track/features/notifications/data/models/notification.dart';

import '../../core/enums/competition_role.dart';
import '../../main.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {

}

class FirebaseApi {

  FirebaseApi._privateConstructor();
  static final FirebaseApi instance = FirebaseApi._privateConstructor();

  final _firebaseMessaging = FirebaseMessaging.instance;


  Future<void> _handleNavigation(RemoteMessage message) async{
    final data = message.data;

    if (data.isEmpty) {
      return;
    }

      final type = data['type'];
      final objectId = data['objectId'];

      if (type == NotificationType.inviteCompetition.name.toString()) {
        // Get competition data
        Competition? competition = await CompetitionService.fetchCompetition(objectId);

        if(competition != null){
          navigatorKey.currentState?.pushNamed(
            '/competition_details',
            arguments: {
              'initTab': 4,
              'enterContext': CompetitionContext.invited,
              'competitionData': competition,
            },
          );
        }
      } else if (type == NotificationType.inviteFriends.name.toString()) {
        navigatorKey.currentState?.pushNamed('/profile',arguments: {
          'uid': objectId,
          'userMode': UserMode.friends,
        });
      }
    }

  // Init notifications
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Handle navigate when app i closed
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Second for app to init main
      Future.delayed(const Duration(seconds: 1), () {
        _handleNavigation(initialMessage);
      });
    }

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // handle click on notification
      _handleNavigation(message);
    });

    // Notification when app is active
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [

              Icon(Icons.notifications,color: AppColors.white,),
              SizedBox(width: 10,),
              Expanded(child: Text(notification.body ?? 'Notification',style: TextStyle(color: AppColors.white),)),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.white,
            onPressed: () {
              _handleNavigation(message);
            },
          ),
        ),
      );
    });
  }

  Future<void> saveUserToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _firebaseMessaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
}