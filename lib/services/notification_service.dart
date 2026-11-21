import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message ID: ${message.messageId}");
  debugPrint("Background notification title: ${message.notification?.title}");
  debugPrint("Background notification data: ${message.data}");
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Function(Map<String, dynamic> data)? onNotificationClicked;

  /// Initialize Push Notifications
  Future<void> initialize({
    required bool useFirebase,
    Function(Map<String, dynamic> data)? onNotificationOpen,
  }) async {
    if (_initialized) return;
    onNotificationClicked = onNotificationOpen;

    if (!useFirebase) {
      debugPrint("NotificationService: Running in local mode (Firebase disabled).");
      return;
    }

    try {
      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request permission (iOS + Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      // 3. Get device token
      try {
        _fcmToken = await _fcm.getToken();
        debugPrint('📲 [FCM Token]: $_fcmToken');
        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_device_token', _fcmToken!);
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // 4. Token refresh listener
      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('📲 [FCM Token Refreshed]: $newToken');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_device_token', newToken);
        notifyListeners();
      });

      // 5. Subscribe to default topics
      try {
        await _fcm.subscribeToTopic('all_learners');
        await _fcm.subscribeToTopic('grammar_daily_reminder');
      } catch (e) {
        debugPrint('Topic subscription notice: $e');
      }

      // 6. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        notifyListeners();
      });

      // 7. Message opened app listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped from background: ${message.notification?.title}');
        onNotificationClicked?.call(message.data);
      });

      // 8. App opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App opened from terminated state: ${initialMessage.notification?.title}');
        onNotificationClicked?.call(initialMessage.data);
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Sync FCM token with user doc in Firestore
  Future<void> syncUserFcmToken(String uid) async {
    if (_fcmToken == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': _fcmToken,
        'fcmLastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM token synced to user doc for $uid');
    } catch (e) {
      debugPrint('Error syncing FCM token to Firestore: $e');
    }
  }
}

