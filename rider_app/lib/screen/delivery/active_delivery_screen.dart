import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import '../../model/delivery_order_model.dart';
import '../../service/socket_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/navigation_launcher.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final DeliveryOrder order;

  const ActiveDeliveryScreen({super.key, required this.order});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late DeliveryOrder _order;
  StreamSubscription? _socketSub;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;

    _socketSub = RiderSocketService().onOrderStatusUpdate.listen((data) {
      if (!mounted) return;
      final incomingId = data['orderId']?.toString();
      if (incomingId == _order.orderId) {
        context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DeliveryLoaded) {
          // If order is completed, safely pop back to dashboard with celebration
          final found = state.activeOrders.where((o) => o.orderId == _order.orderId).toList();
          if (found.isEmpty && !_isPopping) {
            _isPopping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Order #${_order.orderId} Delivered Successfully! +₹45 Payout added.'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 4),
                ),
              );
            });
          } else if (found.isNotEmpty) {
            setState(() {
              _order = found.first;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: CustomText.title('Order #${_order.orderId}', fontWeight: FontWeight.bold),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: Responsive.w(16)),
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(4)),
              decoration: BoxDecoration(
                color: _order.status == 'out_for_delivery'
                    ? AppColors.info.withOpacity(0.15)
                    : AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(Responsive.w(12)),
              ),
              child: Center(
                child: CustomText.caption(
                  _order.status == 'out_for_delivery'
                      ? 'ON THE WAY'
                      : (_order.status == 'accepted'
                          ? 'ACCEPTED ✔'
                          : (_order.status == 'ready_for_pickup'
                              ? 'READY FOR PICKUP'
                              : (_order.status == 'preparing' ? 'STORE PACKING' : 'PENDING PACKING'))),
                  color: _order.status == 'out_for_delivery'
                      ? AppColors.info
                      : (_order.status == 'accepted'
                          ? AppColors.success
                          : (_order.status == 'ready_for_pickup' ? AppColors.warning : AppColors.warning)),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: CommonBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.w(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Progress Indicator
                  _buildProgressTracker(),
                  SizedBox(height: Responsive.h(20)),

                  // STORE PICKUP CARD
                  _buildStorePickupCard(),
                  SizedBox(height: Responsive.h(16)),

                  // CUSTOMER DROP CARD
                  _buildCustomerDropCard(),
                  SizedBox(height: Responsive.h(16)),

                  // ORDER ITEMS CHECKLIST
                  _buildItemsCard(),
                  SizedBox(height: Responsive.h(16)),

                  // PAYMENT SUMMARY
                  _buildPaymentSummaryCard(),
                  SizedBox(height: Responsive.h(30)),

                  // ACTION BUTTON (Pick up or Mark Delivered)
                  _buildActionControls(context),
                  SizedBox(height: Responsive.h(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Progress tracker
  // --------------------------------------------------------------------------
  Widget _buildProgressTracker() {
    final isAccepted = _order.status == 'accepted';
    final isOut = _order.status == 'out_for_delivery';

    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _stepNode(1, 'Accepted', true, (!isAccepted && !isOut) ? true : isAccepted),
          Expanded(
            child: Container(
              height: 3,
              color: (isAccepted || isOut) ? AppColors.success : AppColors.lightGray,
            ),
          ),
          _stepNode(2, 'Store Pickup', isOut ? true : false, isOut ? false : false),
          Expanded(
            child: Container(
              height: 3,
              color: isOut ? AppColors.success : AppColors.lightGray,
            ),
          ),
          _stepNode(3, 'Customer Drop', isOut ? true : false, isOut ? true : false),
        ],
      ),
    );
  }

  Widget _stepNode(int step, String label, bool reached, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: Responsive.w(14),
          backgroundColor: reached ? (active ? AppColors.primary : AppColors.success) : AppColors.lightGray,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: Responsive.sp(12),
              fontWeight: FontWeight.bold,
              color: reached ? Colors.white : AppColors.grayFont,
            ),
          ),
        ),
        SizedBox(height: Responsive.h(4)),
        CustomText.caption(
          label,
          fontSize: Responsive.sp(11),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? AppColors.primary : AppColors.grayFont,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Store Pickup Card
  // --------------------------------------------------------------------------
  Widget _buildStorePickupCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.w(8)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              ),
              SizedBox(width: Responsive.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.caption('STEP 1: PICKUP FROM STORE', color: AppColors.primary, fontWeight: FontWeight.bold),
                    CustomText.title(_order.storeName, fontSize: Responsive.sp(15), fontWeight: FontWeight.bold),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(10)),
          CustomText.body(_order.storeAddress, fontSize: Responsive.sp(13)),
          SizedBox(height: Responsive.h(14)),

          // Navigation & Call Store buttons
          Row(
            children: [
              // Google Maps button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    NavigationLauncher.openGoogleMapsDirections(
                      _order.storeLat,
                      _order.storeLng,
                      label: _order.storeName,
                    );
                  },
                  icon: const Icon(Icons.directions_outlined, size: 18, color: Colors.white),
                  label: const Text('Navigate to Store', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(10))),
                  ),
                ),
              ),
              if (_order.storePhone.isNotEmpty) ...[
                SizedBox(width: Responsive.w(8)),
                IconButton.filledTonal(
                  onPressed: () {
                    NavigationLauncher.callPhoneNumber(_order.storePhone);
                  },
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  tooltip: 'Call Store',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Customer Drop Card
  // --------------------------------------------------------------------------
  Widget _buildCustomerDropCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.w(8)),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.success, size: 20),
              ),
              SizedBox(width: Responsive.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.caption('STEP 2: DELIVER TO CITIZEN', color: AppColors.success, fontWeight: FontWeight.bold),
                    CustomText.title(_order.receiverName, fontSize: Responsive.sp(15), fontWeight: FontWeight.bold),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(10)),
          CustomText.body(_order.dropAddress, fontSize: Responsive.sp(13)),
          SizedBox(height: Responsive.h(14)),

          // Navigation & Call Customer buttons
          Row(
            children: [
              // Google Maps button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    RiderSocketService().sendLocation(
                      orderId: _order.orderId,
                      latitude: (_order.storeLat + _order.dropLat) / 2,
                      longitude: (_order.storeLng + _order.dropLng) / 2,
                      riderId: _order.riderId,
                    );
                    NavigationLauncher.openGoogleMapsDirections(
                      _order.dropLat,
                      _order.dropLng,
                      label: 'Citizen Delivery Location',
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                  label: const Text('Navigate to Customer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(10))),
                  ),
                ),
              ),
              if (_order.receiverPhone.isNotEmpty) ...[
                SizedBox(width: Responsive.w(8)),
                IconButton.filledTonal(
                  onPressed: () {
                    NavigationLauncher.callPhoneNumber(_order.receiverPhone);
                  },
                  icon: const Icon(Icons.phone, color: AppColors.success),
                  tooltip: 'Call Customer',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Items Checklist Card
  // --------------------------------------------------------------------------
  Widget _buildItemsCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.title('Items to Verify (${_order.items.length})', fontSize: Responsive.sp(14)),
              const Icon(Icons.checklist_rounded, color: AppColors.grayFont, size: 20),
            ],
          ),
          const Divider(height: 20),
          ..._order.items.map((item) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: Responsive.h(6)),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          fontSize: Responsive.sp(11),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText.title(item.title, fontSize: Responsive.sp(13)),
                        CustomText.caption(item.unit, fontSize: Responsive.sp(11)),
                      ],
                    ),
                  ),
                  CustomText.title('₹${(item.price * item.quantity).toStringAsFixed(0)}', fontSize: Responsive.sp(13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Payment Summary Card
  // --------------------------------------------------------------------------
  Widget _buildPaymentSummaryCard() {
    final isPrepaid = _order.paymentStatus == 'paid';

    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.title('Payment & Collection', fontSize: Responsive.sp(14)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.body('Payment Mode'),
              CustomText.title(_order.paymentMethod, fontSize: Responsive.sp(13)),
            ],
          ),
          SizedBox(height: Responsive.h(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.body('Payment Status'),
              SizedBox(width: Responsive.w(8)),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(8), vertical: Responsive.h(2)),
                  decoration: BoxDecoration(
                    color: isPrepaid ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPrepaid ? 'PREPAID ONLINE' : 'COLLECT CASH ON DELIVERY',
                    style: TextStyle(
                      fontSize: Responsive.sp(11),
                      fontWeight: FontWeight.bold,
                      color: isPrepaid ? AppColors.success : AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.body('Total Bill Amount'),
              CustomText.title('₹${_order.grandTotal.toStringAsFixed(0)}', fontSize: Responsive.sp(15), fontWeight: FontWeight.bold),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.title('Your Payout for this trip', color: AppColors.success),
              CustomText.title('₹${_order.estimatedPayout.toStringAsFixed(0)}', color: AppColors.success, fontWeight: FontWeight.bold),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Action Controls (Confirm Pickup or Mark Delivered)
  // --------------------------------------------------------------------------
  Widget _buildActionControls(BuildContext context) {
    final isOut = _order.status == 'out_for_delivery';
    // Both 'accepted' and legacy 'ready_for_pickup' show the store-pickup button
    final isPrePickup = _order.status == 'accepted' || _order.status == 'ready_for_pickup';

    if (isPrePickup) {
      return SizedBox(
        width: double.infinity,
        height: Responsive.h(54),
        child: ElevatedButton.icon(
          onPressed: () {
            RiderSocketService().sendLocation(
              orderId: _order.orderId,
              latitude: _order.storeLat,
              longitude: _order.storeLng,
              riderId: _order.riderId,
            );
            context.read<DeliveryBloc>().add(ConfirmStorePickupEvent(_order.orderId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order picked up from store! Now navigate to customer drop address.'),
                backgroundColor: AppColors.info,
              ),
            );
          },
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          label: const Text(
            'Confirm Store Pickup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(14))),
          ),
        ),
      );
    } else if (isOut) {
      return SizedBox(
        width: double.infinity,
        height: Responsive.h(54),
        child: ElevatedButton.icon(
          onPressed: () {
            _showDeliveryConfirmationDialog(context);
          },
          icon: const Icon(Icons.task_alt_rounded, color: Colors.white),
          label: const Text(
            'Confirm Delivered to Customer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(14))),
          ),
        ),
      );
    }
    // Fallback: order in an intermediate state (e.g. still appearing in a stale list)
    return const SizedBox.shrink();
  }

  void _showDeliveryConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Delivery?'),
        content: Text(
          'Have you handed over the order items to ${_order.receiverName} at ${_order.dropAddress}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              RiderSocketService().sendLocation(
                orderId: _order.orderId,
                latitude: _order.dropLat,
                longitude: _order.dropLng,
                riderId: _order.riderId,
              );
              context.read<DeliveryBloc>().add(ConfirmDeliveredEvent(_order.orderId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Yes, Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
