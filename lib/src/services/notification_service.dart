import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initFCM() async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not authenticated. Cannot save FCM token.');
      return;
    }
    final uid = user.uid;
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> sendNotificationToAll(
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'sendNotificationToAll',
    );
    await callable.call({'title': title, 'body': body, 'payload': data ?? {}});
  }
}
