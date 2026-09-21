import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import '../../constants/route_constants.dart';
import '../../hive/hive_service.dart';
import '../../model/delivery_order_model.dart';
import '../../network/rider_api_service.dart';
import '../../service/socket_service.dart';
import '../../service/background_task_handler.dart';
import '../../utils/app_colors.dart';
import '../../utils/navigation_launcher.dart';
import '../../utils/responsive_helper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../../widget/available_order_card.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with WidgetsBindingObserver {
  StreamSubscription? _availableSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _assignedSub;
  StreamSubscription? _dispatchSub;
  StreamSubscription? _dispatchCancelledSub;
  Timer? _gpsPingTimer;
  final Set<String> _acceptingOrderIds = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isPlayingSound = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Rider app closed / killed by user -> Turn OFFLINE immediately
      HiveService.setIsOnline(false);
      RiderSocketService().sendGpsPing(0, 0, false);
      RiderSocketService().dispose();
      FlutterForegroundTask.stopService();
    }
    // paused / inactive: foreground service keeps socket alive + alerts rider!
  }

  Future<void> _playAlertSound() async {
    if (_isPlayingSound) return;
    _isPlayingSound = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sound/alert.wav'));
    } catch (_) {
      try {
        await _audioPlayer.play(AssetSource('assets/sound/alert.wav'));
      } catch (_) {}
    }
  }

  Future<void> _stopAlertSound() async {
    if (!_isPlayingSound) return;
    _isPlayingSound = false;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _syncRealRiderProfile() async {
    final userId = HiveService.userId;
    if (userId.isEmpty) return;
    final profile = await RiderApiService.fetchRiderProfile(userId);
    if (profile != null && mounted) {
      final name = profile['userName']?.toString();
      final phone = profile['phone']?.toString();
      final vType = profile['vehicleType']?.toString();
      final vNum = profile['vehicleNumber']?.toString();
      if (name != null && name.isNotEmpty) await HiveService.setUserName(name);
      if (phone != null && phone.isNotEmpty) await HiveService.setUserPhone(phone);
      if (vType != null && vType.isNotEmpty) await HiveService.setVehicleType(vType);
      if (vNum != null && vNum.isNotEmpty) await HiveService.setVehicleNumber(vNum);
      setState(() {});
    }
  }

  void _startGpsPings() {
    _gpsPingTimer?.cancel();
    _sendGpsPing();
    _gpsPingTimer = Timer.periodic(const Duration(seconds: 20), (_) => _sendGpsPing());
  }

  Future<void> _sendGpsPing() async {
    if (!HiveService.isOnline) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 5));
      RiderSocketService().sendGpsPing(pos.latitude, pos.longitude, true);
    } catch (e) {
      RiderSocketService().sendGpsPing(0, 0, HiveService.isOnline);
    }
  }

  Future<void> _handleToggleOnline(bool targetOnline) async {
    if (targetOnline) {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showLocationDialog(
          title: 'GPS Location Disabled',
          content: 'GPS / Location services are required to go online and receive delivery order alerts nearby. Please turn on GPS on your device.',
        );
        return;
      }

      // 2. Check location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showLocationDialog(
          title: 'Location Permission Required',
          content: 'Location permission is mandatory to go online and take delivery orders. Please grant location access in App Settings.',
        );
        return;
      }

      // 3. Acquire current location fix to verify GPS before going online
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 8));

        await HiveService.setIsOnline(true);
        if (!mounted) return;
        context.read<DeliveryBloc>().add(ToggleDutyEvent(true));
        RiderSocketService().sendGpsPing(pos.latitude, pos.longitude, true);
        _startGpsPings();
        // Start foreground service so background socket stays alive
        await _startForegroundService();
      } catch (e) {
        if (!mounted) return;
        _showLocationDialog(
          title: 'Unable to Get GPS Signal',
          content: 'Could not fetch your location signal. Please ensure you have clear GPS signal to go online.',
        );
      }
    } else {
      // Turn OFFLINE
      await HiveService.setIsOnline(false);
      if (!mounted) return;
      context.read<DeliveryBloc>().add(ToggleDutyEvent(false));
      _gpsPingTimer?.cancel();
      RiderSocketService().sendGpsPing(0, 0, false);
      // Stop foreground service — rider is offline
      await _stopForegroundService();
    }
  }

  void _showLocationDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(child: CustomText.title(title, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: CustomText.body(content, fontSize: 13),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptOrder(DeliveryOrder order) async {
    if (_acceptingOrderIds.contains(order.orderId)) return;

    setState(() {
      _acceptingOrderIds.add(order.orderId);
    });

    final riderId = HiveService.userId;
    final riderName = HiveService.userName.isNotEmpty ? HiveService.userName : 'Express Rider';
    final riderPhone = HiveService.userPhone;
    final vehicleNumber = HiveService.vehicleNumber.isNotEmpty ? HiveService.vehicleNumber : 'KA-01-EE-4521';

    try {
      final res = await RiderApiService.acceptOrder(
        orderId: order.orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
        vehicleNumber: vehicleNumber,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _stopAlertSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted Order #${order.orderId}! Navigate to store for pickup.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      } else if (res['alreadyAccepted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? '⚠️ Order was already claimed by another delivery partner.'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
        // Refresh deliveries to remove the claimed order from this rider's screen
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to accept order. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting delivery: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _acceptingOrderIds.remove(order.orderId);
        });
      }
    }
  }

  // ─── Foreground Task Setup ──────────────────────────────────────────────

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rider_duty_channel',
        channelName: 'Rider Duty Status',
        channelDescription: 'Shows when rider is on duty and listening for orders',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000), // ping every 15s
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> _startForegroundService() async {
    await FlutterForegroundTask.requestNotificationPermission();
    // Save real rider ID so background isolate can read it
    final riderId = HiveService.userId.isNotEmpty
        ? HiveService.userId
        : HiveService.userPhone;
    await FlutterForegroundTask.saveData(key: 'riderId', value: riderId);
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: '🟢 GoGovernment — On Duty',
      notificationText: 'Listening for nearby delivery orders...',
      callback: startCallback,
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  // ─── Local Notifications Init ───────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Tapping notification brings app to foreground (handled by OS)
      },
    );
    // Create the high-priority order alert channel
    const channel = AndroidNotificationChannel(
      'rider_order_alerts',
      'Order Alerts',
      description: 'Heads-up alerts for incoming delivery orders',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alert'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(LoadDeliveriesEvent());

    // Init foreground task config & local notification channel
    _initForegroundTask();
    _initLocalNotifications();

    // Connect to real-time WebSocket events & sync backend rider profile
    RiderSocketService().init();
    _syncRealRiderProfile();
    _startGpsPings();

    // If rider was already ONLINE before app restart, resume service
    if (HiveService.isOnline) {
      _startForegroundService();
    }

    _availableSub = RiderSocketService().onOrderAvailable.listen((_) {
      if (mounted) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });
    _statusSub = RiderSocketService().onOrderStatusUpdate.listen((_) {
      if (mounted) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });
    _assignedSub = RiderSocketService().onOrderAssigned.listen((_) {
      if (mounted) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });

    // Targeted 30-second dispatch alert
    _dispatchSub = RiderSocketService().onOrderDispatch.listen((_) {
      if (mounted) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });

    // Refresh when dispatch is cancelled / claimed by another rider
    _dispatchCancelledSub = RiderSocketService().onOrderDispatchCancelled.listen((_) {
      if (mounted) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });

    // Register App Lifecycle Observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAlertSound();
    _availableSub?.cancel();
    _statusSub?.cancel();
    _assignedSub?.cancel();
    _dispatchSub?.cancel();
    _dispatchCancelledSub?.cancel();
    _gpsPingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: CommonBackground(
        child: SafeArea(
          child: BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, state) {
              final isOnline = state is DeliveryLoaded ? state.isOnline : HiveService.isOnline;
              final available = state is DeliveryLoaded ? state.availableOrders : <DeliveryOrder>[];
              final active = state is DeliveryLoaded ? state.activeOrders : <DeliveryOrder>[];
              final earnings = state is DeliveryLoaded ? state.totalEarnings : HiveService.totalEarnings;
              final completed = state is DeliveryLoaded ? state.completedCount : HiveService.completedCount;

              if (active.isEmpty && available.isNotEmpty && isOnline) {
                _playAlertSound();
              } else {
                _stopAlertSound();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(18), vertical: Responsive.h(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      _buildHeader(context, isOnline),
                      SizedBox(height: Responsive.h(16)),

                      // Metrics Cards Row
                      _buildMetricsRow(earnings, completed, active.length),
                      SizedBox(height: Responsive.h(20)),

                      // Active Tasks section
                      if (active.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                            ),
                            SizedBox(width: Responsive.w(8)),
                            CustomText.title('Active Delivery In Progress', fontSize: Responsive.sp(16)),
                          ],
                        ),
                        SizedBox(height: Responsive.h(10)),
                        ...active.map((order) => _buildActiveOrderCard(context, order)),
                        SizedBox(height: Responsive.h(20)),
                      ],

                      // Available Deliveries Feed (Only shown when rider has NO active order)
                      if (active.isEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? AppColors.success : AppColors.grayFont,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                CustomText.title('Available Deliveries', fontSize: Responsive.sp(16)),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(4)),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.w(12)),
                              ),
                              child: CustomText.caption(
                                '${available.length} Nearby',
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(12)),

                        if (!isOnline)
                          _buildOfflineNotice()
                        else if (available.isEmpty)
                          _buildNoOrdersState()
                        else
                          ...available.map(
                            (order) => AvailableOrderCard(
                              key: ValueKey(order.orderId),
                              order: order,
                              isAccepting: _acceptingOrderIds.contains(order.orderId),
                              onAccept: () => _handleAcceptOrder(order),
                              onExpired: () {
                                if (mounted) {
                                  context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
                                }
                              },
                            ),
                          ),
                      ],

                      SizedBox(height: Responsive.h(30)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ----------------------------------------------------
  // Header Widget
  // ----------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isOnline) {
    final riderName = HiveService.userName.isNotEmpty ? HiveService.userName : 'Rider Partner';

    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.w(22),
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.title(riderName, fontSize: Responsive.sp(16), fontWeight: FontWeight.bold),
                CustomText.caption(
                  '${HiveService.vehicleType} · ${HiveService.vehicleNumber}',
                  color: AppColors.grayFont,
                ),
              ],
            ),
          ),
          // Duty Toggle Button (Mandatory GPS check required to go online)
          GestureDetector(
            onTap: () => _handleToggleOnline(!isOnline),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(12), vertical: Responsive.h(6)),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success.withOpacity(0.12) : AppColors.lightGray,
                borderRadius: BorderRadius.circular(Responsive.w(20)),
                border: Border.all(
                  color: isOnline ? AppColors.success : AppColors.grayFont,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 16,
                    color: isOnline ? AppColors.success : AppColors.grayFont,
                  ),
                  SizedBox(width: Responsive.w(6)),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      fontWeight: FontWeight.bold,
                      color: isOnline ? AppColors.success : AppColors.grayFont,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Metrics Row
  // ----------------------------------------------------
  Widget _buildMetricsRow(double earnings, int completed, int activeCount) {
    return Row(
      children: [
        Expanded(
          child: _metricCard('Today\'s Payout', '₹${earnings.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, AppColors.success),
        ),
        SizedBox(width: Responsive.w(10)),
        Expanded(
          child: _metricCard('Completed', '$completed', Icons.check_circle_outline, AppColors.primary),
        ),
        SizedBox(width: Responsive.w(10)),
        Expanded(
          child: _metricCard('Active', '$activeCount', Icons.pedal_bike_outlined, AppColors.warning),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(height: Responsive.h(6)),
          CustomText.caption(label, fontSize: Responsive.sp(11), color: AppColors.grayFont),
          SizedBox(height: Responsive.h(2)),
          CustomText.title(value, fontSize: Responsive.sp(16), fontWeight: FontWeight.bold, color: AppColors.black),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Active Order Card
  // ----------------------------------------------------
  Widget _buildActiveOrderCard(BuildContext context, DeliveryOrder order) {
    final isOutForDelivery = order.status == 'out_for_delivery';

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(12)),
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Warm highlight card
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.warning.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(8), vertical: Responsive.h(3)),
                decoration: BoxDecoration(
                  color: isOutForDelivery ? AppColors.info : AppColors.warning,
                  borderRadius: BorderRadius.circular(Responsive.w(6)),
                ),
                child: CustomText.caption(
                  isOutForDelivery ? 'OUT FOR DELIVERY' : 'PICKUP READY',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomText.caption(
                'Order #${order.orderId}',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),

          // Store & Customer summary
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: CustomText.title(
                  order.storeName,
                  fontSize: Responsive.sp(14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(6)),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.success),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: CustomText.body(
                  order.dropAddress,
                  fontSize: Responsive.sp(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),

          // Navigation and Details buttons
          Row(
            children: [
              // Google Maps Direction Launcher
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isOutForDelivery) {
                      NavigationLauncher.openGoogleMapsDirections(order.dropLat, order.dropLng, label: 'Customer Location');
                    } else {
                      NavigationLauncher.openGoogleMapsDirections(order.storeLat, order.storeLng, label: 'Store Location');
                    }
                  },
                  icon: const Icon(Icons.navigation_outlined, size: 18, color: AppColors.primary),
                  label: Text(
                    isOutForDelivery ? 'To Customer' : 'To Store',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(10))),
                  ),
                ),
              ),
              SizedBox(width: Responsive.w(10)),

              // Open Details Screen
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RouteConstants.activeDelivery, arguments: order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(10))),
                  ),
                  child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // States
  // ----------------------------------------------------
  Widget _buildOfflineNotice() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.power_off_rounded, size: 48, color: AppColors.grayFont),
          SizedBox(height: Responsive.h(12)),
          CustomText.title('You are currently Offline', fontSize: Responsive.sp(16), fontWeight: FontWeight.bold),
          SizedBox(height: Responsive.h(6)),
          CustomText.body(
            'Turn on Duty switch at top right to start receiving available orders and payouts.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoOrdersState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.two_wheeler_outlined, size: 48, color: AppColors.outliner),
          SizedBox(height: Responsive.h(12)),
          CustomText.title('Searching for nearby orders...', fontSize: Responsive.sp(15), fontWeight: FontWeight.bold),
          SizedBox(height: Responsive.h(6)),
          CustomText.body(
            'Keep app open. When citizens place orders at government stores, they will appear here.',
            textAlign: TextAlign.center,
            fontSize: Responsive.sp(12.5),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Bottom Navigation Bar
  // ----------------------------------------------------
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(vertical: Responsive.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.dashboard_rounded, 'Deliveries', true, () {}),
          _navItem(Icons.account_balance_wallet_outlined, 'Earnings', false, () {
            Navigator.pushNamed(context, RouteConstants.earnings);
          }),
          _navItem(Icons.person_outline_rounded, 'Profile', false, () {
            Navigator.pushNamed(context, RouteConstants.profile);
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : AppColors.grayFont, size: 24),
          SizedBox(height: Responsive.h(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.sp(11),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.grayFont,
            ),
          ),
        ],
      ),
    );
  }
}
