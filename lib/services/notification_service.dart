import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize local notification plugin for Android & iOS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification clicked: ${response.payload}');
        },
      );

      // Request notification permission for Android 13+ (API level 33+)
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Show a local push notification displaying the OTP code
  static Future<void> showOtpNotification({
    required String otp,
    String title = '🔐 Your OTP Verification Code',
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'otp_channel',
        'OTP Notifications',
        channelDescription: 'Notifications for receiving OTP test codes',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Random or unique ID so each OTP pops up cleanly
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: 'Your verification code is $otp. Use this code to complete verification.',
        notificationDetails: notificationDetails,
        payload: otp,
      );
      debugPrint('[NotificationService] Displayed OTP Notification: $otp');
    } catch (e) {
      debugPrint('[NotificationService] Error showing OTP notification: $e');
    }
  }
}
