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
import '../../utils/app_colors.dart';
import '../../utils/navigation_launcher.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  StreamSubscription? _availableSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _assignedSub;
  final Set<String> _acceptingOrderIds = {};

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

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(LoadDeliveriesEvent());

    // Connect to real-time WebSocket events (zero polling, zero battery drain)
    RiderSocketService().init();
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
  }

  @override
  void dispose() {
    _availableSub?.cancel();
    _statusSub?.cancel();
    _assignedSub?.cancel();
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

                      // Available Deliveries Feed
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
                        ...available.map((order) => _buildAvailableOrderCard(context, order)),

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
          // Duty Toggle Button
          GestureDetector(
            onTap: () {
              context.read<DeliveryBloc>().add(ToggleDutyEvent(!isOnline));
            },
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
  // Available Order Card
  // ----------------------------------------------------
  Widget _buildAvailableOrderCard(BuildContext context, DeliveryOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(12)),
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID + Payout Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.w(6)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  CustomText.title('#${order.orderId}', fontSize: Responsive.sp(14), fontWeight: FontWeight.bold),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(4)),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 14, color: AppColors.success),
                    CustomText.title(
                      '${order.estimatedPayout.toStringAsFixed(0)} Earn',
                      fontSize: Responsive.sp(13),
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),

          // Store Pickup Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.store, size: 16, color: AppColors.primary),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title(order.storeName, fontSize: Responsive.sp(13)),
                    CustomText.caption(order.storeAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(10)),

          // Customer Drop Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.success),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title('Drop: ${order.receiverName}', fontSize: Responsive.sp(13)),
                    CustomText.caption(order.dropAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),

          // Action Buttons: Google Maps Direction Preview & Accept Order
          Row(
            children: [
              // Google Maps preview button
              IconButton(
                onPressed: () {
                  NavigationLauncher.openGoogleMapsDirections(order.storeLat, order.storeLng, label: 'Store Location');
                },
                icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                tooltip: 'Preview route in Google Maps',
              ),
              SizedBox(width: Responsive.w(8)),

              // Accept Button
              Expanded(
                child: SizedBox(
                  height: Responsive.h(44),
                  child: ElevatedButton(
                    onPressed: _acceptingOrderIds.contains(order.orderId)
                        ? null
                        : () => _handleAcceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
                    ),
                    child: _acceptingOrderIds.contains(order.orderId)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 18, color: Colors.white),
                              SizedBox(width: Responsive.w(6)),
                              const Text(
                                'Accept Delivery',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
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
