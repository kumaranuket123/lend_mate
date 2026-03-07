import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Must be top-level — called by FCM when the app is terminated/background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time FCM calls this.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'lendmate_channel';
  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    'LendMate Notifications',
    description: 'Loan and payment alerts from LendMate',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Register background handler (must be called before anything else)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermission();

    // Save token now if already logged in; also react to future sign-ins
    if (supabase.auth.currentUser != null) await _saveToken();

    supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) await _saveToken();
    });

    // Refresh token whenever FCM rotates it
    _fcm.onTokenRefresh.listen(_persistToken);

    // Show banner for messages that arrive while app is in foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // App brought to foreground by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // App launched from a terminated state via notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  // ── Local notifications setup ──────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(initSettings);

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // On iOS/Android, show notification banner even when app is foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _saveToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _persistToken(token);
    } catch (e) {
      debugPrint('[FCM] Token fetch error: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    debugPrint('[FCM] Saving token for uid=$uid');
    await supabase
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', uid);
  }

  // ── Message handling ───────────────────────────────────────────────────────

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped — data: ${message.data}');
    // Optional: navigate to /notifications using your router
    // appRouter.go('/notifications');
  }

}