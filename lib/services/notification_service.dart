import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Background message handler — MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _appInitialized = false;

  // ═══════════════════════════════════════════════════════════
  // STEP 1 — call once in main() BEFORE runApp
  // Sets up background handler + local notification channel
  // Does NOT need a logged-in user
  // ═══════════════════════════════════════════════════════════
  Future<void> initializeApp() async {
    if (_appInitialized) return;
    _appInitialized = true;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Setup local notifications
    await _setupLocalNotifications();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Listen for background notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data);
    });

    debugPrint('[FCM] ✅ App-level init complete');
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 2 — call this RIGHT AFTER successful login
  // Generates and saves the FCM token
  // ═══════════════════════════════════════════════════════════
  Future<void> initializeForUser(String userId) async {
    debugPrint('[FCM] ▶ initializeForUser called for: $userId');

    try {
      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final status = settings.authorizationStatus;
      debugPrint('[FCM] Permission status: $status');

      if (status == AuthorizationStatus.denied) {
        debugPrint('[FCM] ❌ Permission DENIED');
        return;
      }

      // Get FCM token
      String? token;
      try {
        token = await _fcm.getToken();
        debugPrint('[FCM] Token: ${token?.substring(0, 20)}...');
      } catch (e) {
        debugPrint('[FCM] ❌ getToken() failed: $e');
        return;
      }

      if (token == null || token.isEmpty) {
        debugPrint('[FCM] ❌ Token is null/empty');
        return;
      }

      // Save to Firestore
      await _db.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint('[FCM] ✅ Token saved');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed');
        _db.collection('users').doc(userId).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });

      // Check initial message (app opened from notification - terminated state)
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        debugPrint('[FCM] App opened from killed notification');
        await Future.delayed(const Duration(milliseconds: 800));
        _handleNotificationNavigation(initial.data);
      }

      debugPrint('[FCM] ✅ User init complete');
    } catch (e, stack) {
      debugPrint('[FCM] ❌ initializeForUser error: $e');
      debugPrint(stack.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 3 — call on logout
  // ═══════════════════════════════════════════════════════════
  Future<void> clearTokenOnLogout(String userId) async {
    try {
      await _db.collection('users').doc(userId).set({
        'fcmToken': '',
      }, SetOptions(merge: true));
      await _fcm.deleteToken();
      debugPrint('[FCM] ✅ Token cleared on logout');
    } catch (e) {
      debugPrint('[FCM] clearToken error: $e');
    }
  }

  // ── Setup local notifications ─────────────────────────────
  Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _local.initialize(
        settings: InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationNavigation(_decodePayload(response.payload));
        },
      );

      // Create Android notification channel
      if (Platform.isAndroid) {
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'smart_erp_channel',
                'Smart ERP Notifications',
                description: 'Exams, results, and study material alerts',
                importance: Importance.high,
                playSound: true,
                enableVibration: true,
              ),
            );
      }
    } catch (e) {
      debugPrint('[FCM] Setup error: $e');
    }
  }

  // ── Show foreground notification ──────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'smart_erp_channel',
      'Smart ERP Notifications',
      channelDescription: 'Exams, results, and study materials',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: _encodePayload(message.data),
      );
    } catch (e) {
      debugPrint('[FCM] Show error: $e');
    }
  }

  // ── Handle notification navigation ────────────────────────
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final context = navigatorKey.currentContext;

    if (context == null || type == null) return;

    switch (type) {
      case 'new_exam':
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/exam_list', (route) => route.isFirst);
        break;

      case 'new_note':
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/notes', (route) => route.isFirst);
        break;

      case 'result_published':
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/my_results', (route) => route.isFirst);
        break;

      case 're_exam_granted':
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/exam_list', (route) => route.isFirst);
        break;

      default:
        debugPrint('[FCM] Unknown type: $type');
    }
  }

  // ── Payload helpers ───────────────────────────────────────
  String _encodePayload(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    return Map.fromEntries(
      payload.split('&').map((e) {
        final parts = e.split('=');
        return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
      }),
    );
  }
}
