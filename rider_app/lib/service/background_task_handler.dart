import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationVisibility; // avoid clash with flutter_foreground_task
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Top-level callback — required by flutter_foreground_task.
/// Must be annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RiderBackgroundTaskHandler());
}

/// Runs inside the Android Foreground Service isolate.
/// Maintains a dedicated socket connection independent of the UI isolate.
/// Sends periodic isOnline=true GPS pings to keep rider ONLINE on server.
class RiderBackgroundTaskHandler extends TaskHandler {
  io.Socket? _socket;
  String _riderId = 'rider_bg';
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'rider_order_alerts';
  static const String _channelName = 'Order Alerts';
  static int _notificationId = 1000;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Read the real rider ID saved by the main isolate before starting service
    final savedId = await FlutterForegroundTask.getData<String>(key: 'riderId');
    if (savedId != null && savedId.isNotEmpty) {
      _riderId = savedId;
    }

    await _initNotifications();
    _connectBackgroundSocket();
  }

  /// Called every 15 seconds by the Foreground Service.
  /// Keeps rider marked ONLINE on server while app is in background.
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_socket != null && _socket!.connected) {
      // Send keepalive ping with isOnline=true so server never marks rider offline
      _socket?.emit('rider:location_ping', {
        'riderId': _riderId,
        'lat': 0,       // no GPS in background to save battery
        'lng': 0,
        'isOnline': true,
        'bgPing': true, // flag for debugging
      });
    } else {
      // Socket dropped — reconnect
      _connectBackgroundSocket();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Send final offline ping before service stops
    if (_socket != null && _socket!.connected) {
      _socket?.emit('rider:location_ping', {
        'riderId': _riderId,
        'lat': 0,
        'lng': 0,
        'isOnline': false,
      });
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ─── Local Notifications Init ─────────────────────────────────────────────

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(settings: initSettings);

    // Create high-importance notification channel with custom alert.wav sound
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alerts for new delivery order assignments',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alert'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ─── Background Socket ────────────────────────────────────────────────────

  void _connectBackgroundSocket() {
    try {
      const serverUrl = 'http://192.168.1.11:5000';

      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(99)
            .build(),
      );

      _socket?.onConnect((_) {
        // Join riders room with the REAL rider ID (not a placeholder)
        // This ensures the server's riderRegistry keeps isOnline=true
        _socket?.emit('join:rider', _riderId);

        // Immediately send an online ping on reconnect
        _socket?.emit('rider:location_ping', {
          'riderId': _riderId,
          'lat': 0,
          'lng': 0,
          'isOnline': true,
          'bgPing': true,
        });
      });

      // Listen for targeted dispatch events
      _socket?.on('order:dispatch', (data) {
        if (data is Map) {
          _showOrderNotification(Map<String, dynamic>.from(data));
        }
      });

      // Listen for general available order events
      _socket?.on('order:available', (data) {
        if (data is Map) {
          _showOrderNotification(Map<String, dynamic>.from(data));
        }
      });

      _socket?.connect();
    } catch (_) {
      // Background isolate — silently swallow exceptions
    }
  }

  // ─── Show Heads-Up Notification ───────────────────────────────────────────

  Future<void> _showOrderNotification(Map<String, dynamic> data) async {
    final storeName = data['storeName']?.toString() ?? 'Store';
    final dropAddress = data['dropAddress']?.toString() ?? 'Customer Location';
    final deliveryFee = data['deliveryFee']?.toString() ?? '';
    final feeText = deliveryFee.isNotEmpty ? ' • ₹$deliveryFee' : '';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alerts for new delivery order assignments',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alert'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      ticker: 'New delivery order available!',
      styleInformation: BigTextStyleInformation(
        '📍 Pickup: $storeName\n🏠 Drop: $dropAddress$feeText'
        '\n\nTap to open and accept the order.',
      ),
    );

    await _notificationsPlugin.show(
      id: _notificationId++,
      title: '🚨 New Delivery Order!',
      body: 'Pickup: $storeName → $dropAddress$feeText',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}
