import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// Top-level handler for background FCM messages (required by Firebase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smart_delivery_notifications', // must match backend channelId
    'Smart Delivery Notifications',
    description: 'Notifications pour les commandes et livraisons',
    importance: Importance.high,
    playSound: true,
  );

  /// Callback when user taps on a notification
  Function(String? orderId)? onNotificationTap;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    // Request permission (iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: User denied notification permission');
      return;
    }

    // Create the Android notification channel
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed');
      _sendTokenToServer(newToken);
    });
  }

  /// Get the FCM token and send it to the backend
  Future<void> registerTokenWithServer() async {
    try {
      debugPrint('\n========== FCM: Getting device token... ==========');
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('========== FCM Token obtained: ${token.substring(0, 20)}... ==========');
        await _sendTokenToServer(token);
      } else {
        debugPrint('========== FCM: Token is NULL! ==========');
      }
    } catch (e, stackTrace) {
      debugPrint('========== FCM: Failed to get/register token: $e ==========');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Remove the FCM token from the backend (call on logout)
  Future<void> unregisterToken() async {
    try {
      await _api.delete('/fcm/token');
      await _messaging.deleteToken();
      debugPrint('FCM token unregistered');
    } catch (e) {
      debugPrint('FCM: Failed to unregister token: $e');
    }
  }

  /// Send the FCM token to the backend
  Future<void> _sendTokenToServer(String token) async {
    try {
      debugPrint('========== FCM: Sending token to server... ==========');
      await _api.post('/fcm/token', {'token': token});
      debugPrint('========== FCM: Token sent to server SUCCESS ==========');
    } catch (e, stackTrace) {
      debugPrint('========== FCM: FAILED to send token to server: $e ==========');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Handle foreground message — show as local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Smart Delivery',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM notification tapped: ${message.data}');
    String? orderId = message.data['orderId'];
    onNotificationTap?.call(orderId);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        String? orderId = data['orderId'];
        onNotificationTap?.call(orderId);
      } catch (e) {
        debugPrint('FCM: Failed to parse notification payload: $e');
      }
    }
  }
}
