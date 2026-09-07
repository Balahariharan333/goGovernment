// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_element
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_map.dart';
import '../../../constants/route_constants.dart';
import '../../../model/address_model.dart';
import '../../../bloc/order_tracking/order_tracking_bloc.dart';
import '../../../bloc/order_tracking/order_tracking_event.dart';
import '../../../bloc/order_tracking/order_tracking_state.dart';
import '../../../bloc/address/address_bloc.dart';
import '../../../bloc/address/address_event.dart';
import '../../../bloc/profile/profile_bloc.dart';
import '../../../bloc/transaction/transaction_bloc.dart';
import '../../../bloc/transaction/transaction_event.dart';

class OrderStatusScreen extends StatefulWidget {
  final String storeType;
  final Map<String, dynamic>? transaction;
  final String? orderId;

  const OrderStatusScreen({
    super.key,
    required this.storeType,
    this.transaction,
    this.orderId,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {

  int get _currentStep => context.read<OrderTrackingBloc>().state.currentStep;

  String _receiverName = '';
  String _receiverPhone = '';
  String _deliveryAddress = '';
  late String _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId ?? widget.transaction?['id']?.toString() ?? 'ORD-123456787654';

    final profile = context.read<ProfileBloc>().state;
    if (profile.name.trim().isNotEmpty) {
      _receiverName = profile.name.trim();
    }
    if (profile.phone.trim().isNotEmpty) {
      _receiverPhone = profile.phone.trim();
    }

    if (widget.transaction?['address'] != null && widget.transaction!['address'].toString().isNotEmpty) {
      _deliveryAddress = widget.transaction!['address'].toString();
    } else {
      final initialAddr = context.read<AddressBloc>().state.selectedAddress;
      if (initialAddr != null) {
        _deliveryAddress = initialAddr.description;
      }
    }

    if (widget.transaction != null) {
      context.read<OrderTrackingBloc>().add(SetTrackingOrderEvent(widget.transaction!));
    }
  }


  final List<String> _statusTitles = [
    'Arriving on time!',
    'Preparing your order',
    'Packing with care',
    'Rider on the way',
    'Ready for pickup'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTrackingBloc, OrderTrackingState>(
      builder: (context, state) {
        final int currentStep = state.currentStep;
        final bool isMapVisible = currentStep > 0;
        final bool isDriverCardVisible = currentStep >= 2;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: AppColors.screenColor,
            body: CommonBackground(
              child: Column(
                children: [
                  // ── ORANGE GRADIENT HEADER ──────────────────────────────
                  _buildStatusHeaderBar(),

                // ── SCROLLABLE CONTENT ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Responsive.w(20),
                      Responsive.h(16),
                      Responsive.w(20),
                      Responsive.h(40),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Manual step & completion tester (for manual testing before API binding)
                        Container(
                          height: Responsive.h(36),
                          margin: EdgeInsets.only(bottom: Responsive.h(10)),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              final bool isActive = currentStep == index;
                              final List<String> stageLabels = [
                                'Placed',
                                'Confirmed',
                                'Packed',
                                'On the Way',
                                'Delivered',
                              ];
                              return Padding(
                                padding: EdgeInsets.only(right: Responsive.w(8)),
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<OrderTrackingBloc>().add(UpdateTrackingStepEvent(index));
                                    if (index == 4) {
                                      context.read<TransactionBloc>().add(
                                        UpdateOrderStatusEvent(orderId: _orderId, status: 'Delivered'),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: Responsive.w(12)),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.primary : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(Responsive.w(18)),
                                      border: Border.all(
                                        color: isActive ? AppColors.primary : Colors.grey.shade300,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Stage ${index + 1}: ${stageLabels[index]}',
                                        style: TextStyle(
                                          color: isActive ? Colors.white : Colors.grey.shade700,
                                          fontSize: Responsive.sp(11),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Manual Test: Complete Order Quick Action Bar
                        Container(
                          margin: EdgeInsets.only(bottom: Responsive.h(16)),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(14),
                            vertical: Responsive.h(10),
                          ),
                          decoration: BoxDecoration(
                            color: currentStep == 4 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            border: Border.all(
                              color: currentStep == 4 ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentStep == 4 ? Icons.check_circle : Icons.science_outlined,
                                color: currentStep == 4 ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                                size: Responsive.w(20),
                              ),
                              SizedBox(width: Responsive.w(10)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText.title(
                                      currentStep == 4 ? 'Order Completed (Test Mode)' : 'Order Complete Test',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: currentStep == 4 ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                    ),
                                    CustomText.subtitle(
                                      currentStep == 4
                                          ? 'Status saved as Delivered in order history'
                                          : 'Mark as Delivered to test completion flow',
                                      fontSize: 10,
                                      color: AppColors.grayFont,
                                    ),
                                  ],
                                ),
                              ),
                              if (currentStep != 4)
                                GestureDetector(
                                  onTap: () {
                                    context.read<OrderTrackingBloc>().add(UpdateTrackingStepEvent(4));
                                    context.read<TransactionBloc>().add(
                                      UpdateOrderStatusEvent(orderId: _orderId, status: 'Delivered'),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order marked as Completed!'),
                                        backgroundColor: Color(0xFF2E7D32),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.w(12),
                                      vertical: Responsive.h(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(Responsive.w(14)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check, color: Colors.white, size: 14),
                                        SizedBox(width: Responsive.w(4)),
                                        CustomText.title(
                                          'Complete',
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 1. Shopping bag (step 0) or Map (steps 1–4)
                        if (!isMapVisible) ...[
                          Center(
                            child: SizedBox(
                              height: Responsive.h(220),
                              width: double.infinity,
                              child: Image.asset(
                                'assets/images/bag.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            height: Responsive.h(220),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Responsive.w(20)),
                              border: Border.all(color: AppColors.outliner, width: 1.2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Responsive.w(18)),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CommonMap(
                                      mapState: currentStep == 4
                                          ? MapState.navigation
                                          : MapState.directions,
                                      isWalkMode: false,
                                    ),
                                  ),
                                  // Store marker
                                  Positioned(
                                    top: Responsive.h(40),
                                    left: Responsive.w(80),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(Responsive.w(6)),
                                      child: Icon(
                                        Icons.store,
                                        color: AppColors.primary,
                                        size: Responsive.w(18),
                                      ),
                                    ),
                                  ),
                                  // Destination marker
                                  Positioned(
                                    bottom: Responsive.h(40),
                                    right: Responsive.w(80),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(Responsive.w(6)),
                                      child: Icon(
                                        Icons.person_pin_circle,
                                        color: Colors.blue.shade800,
                                        size: Responsive.w(18),
                                      ),
                                    ),
                                  ),
                                  // Rider moving icon
                                  if (currentStep >= 2 && currentStep <= 3)
                                    Positioned(
                                      top: currentStep == 2 ? Responsive.h(90) : Responsive.h(130),
                                      left: currentStep == 2 ? Responsive.w(120) : Responsive.w(180),
                                      child: Container(
                                        padding: EdgeInsets.all(Responsive.w(4)),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.motorcycle,
                                          color: Colors.white,
                                          size: Responsive.w(14),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: Responsive.h(20)),

                        // 2. Status summary card with progress dots
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.w(16)),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(24)),
                            border: Border.all(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText.title(
                                    _statusTitles[currentStep],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  CustomText.title(
                                    '10:14 pm',
                                    fontSize: 13,
                                    color: AppColors.grayFont,
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.h(4)),
                              CustomText.subtitle(
                                currentStep == 4
                                    ? 'Awaiting your pickup'
                                    : 'Your order is being processed by the merchant',
                                fontSize: 12,
                                color: AppColors.grayFont,
                              ),
                              SizedBox(height: Responsive.h(16)),
                              // Progress dots
                              Row(
                                children: List.generate(4, (index) {
                                  final bool isDone = currentStep > index;
                                  final bool isCurrent = currentStep == index;
                                  return Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: Responsive.w(12),
                                          height: Responsive.w(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (isDone || isCurrent)
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        if (index < 3)
                                          Expanded(
                                            child: Container(
                                              height: Responsive.h(2),
                                              color: isDone
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.h(20)),

                        // 3. Driver card (step 2+)
                        if (isDriverCardVisible) ...[
                          _buildDriverDetailCard(),
                          SizedBox(height: Responsive.h(20)),
                        ],

                        // 4. Delivery details
                        _buildDeliveryDetailsCard(),
                        SizedBox(height: Responsive.h(20)),

                        // 5. Order number
                        _buildOrderNumberCard(),
                        SizedBox(height: Responsive.h(20)),

                        // 6. Help card
                        _buildHelpCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildStatusHeaderBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.outliner, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + Responsive.h(16),
        bottom: Responsive.h(16),
        left: Responsive.w(20),
        right: Responsive.w(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteConstants.main,
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  width: Responsive.w(36),
                  height: Responsive.w(36),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                ),
              ),
              CustomText.title(
                _statusTitles[_currentStep],
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              Container(
                width: Responsive.w(36),
                height: Responsive.w(36),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.reply,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),

          // White dynamic Arrived/Time status capsule
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(16),
              vertical: Responsive.h(6),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.w(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentStep == 4 ? 'Arrived ' : 'Arriving in 21 mins · On time ',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.refresh,
                  size: 10,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetailCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        border: Border.all(color: Colors.green.shade200, width: 1.0),
      ),
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: Responsive.w(38),
                height: Responsive.w(38),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title(
                      'Akram Ali',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText.subtitle(
                      '20k+ orders delivered',
                      fontSize: 10,
                      color: Colors.green.shade800,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),

          // Message/Call buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.riderChat,
                      arguments: 'Akram Ali',
                    );
                  },
                  child: Container(
                    height: Responsive.h(38),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(19)),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                          size: Responsive.w(14),
                        ),
                        SizedBox(width: Responsive.w(6)),
                        CustomText.title(
                          'Message',
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Show a Dial pop-up trigger
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dialing Akram Ali (+91 98765 12345)...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Container(
                    height: Responsive.h(38),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(19)),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: AppColors.primary,
                          size: Responsive.w(14),
                        ),
                        SizedBox(width: Responsive.w(6)),
                        CustomText.title(
                          'Call',
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Widget _buildDeliveryDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        border: Border.all(
          color: AppColors.outliner,
          width: Responsive.w(1.2),
        ),
      ),
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.header(
            'All your delivery details in one place',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          SizedBox(height: Responsive.h(16)),

          // Receiver row info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_android,
                color: Colors.grey,
                size: Responsive.w(14),
              ),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: CustomText.title(
                  '$_receiverName, $_receiverPhone',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final res = await Navigator.of(context).pushNamed(
                    RouteConstants.addressBook,
                    arguments: true,
                  );
                  if (res != null && res is AddressModel) {
                    if (mounted) {
                      context.read<AddressBloc>().add(SelectActiveAddressEvent(res));
                    }
                    setState(() {
                      _receiverPhone = res.phone;
                    });
                  }
                },
                child: CustomText.title(
                  'Edit',
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          const Divider(height: 1),
          SizedBox(height: Responsive.h(12)),

          // Address row info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: Responsive.w(14),
              ),
              SizedBox(width: Responsive.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Delivery at ',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          'Work',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),
                    CustomText.title(
                      _deliveryAddress,
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final res = await Navigator.of(context).pushNamed(
                    RouteConstants.addressBook,
                    arguments: true,
                  );
                  if (res != null && res is AddressModel) {
                    if (mounted) {
                      context.read<AddressBloc>().add(SelectActiveAddressEvent(res));
                    }
                    setState(() {
                      _deliveryAddress = res.description;
                    });
                  }
                },
                child: CustomText.title(
                  'Edit',
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getResolvedTransaction() {
    if (widget.transaction != null) {
      return Map<String, dynamic>.from(widget.transaction!);
    }
    final String defaultStore = widget.storeType == 'food'
        ? 'Burger King & Cafe'
        : (widget.storeType == 'grocery' ? 'Fresh Mart Grocery' : 'Apollo Pharmacy');
    return {
      'id': _orderId,
      'title': defaultStore,
      'subtitle': 'Order placed · Processing',
      'amount': '-₹199.00',
      'isPositive': false,
      'status': _statusTitles[_currentStep.clamp(0, _statusTitles.length - 1)],
      'date': 'Today',
      'items': [
        {
          'title': widget.storeType == 'food' ? 'Classic Burger Combo' : 'Health Essentials',
          'price': '₹ 199.00',
          'qty': 1,
          'image': 'assets/images/product1.png',
        }
      ],
      'address': _deliveryAddress,
      'listingPrice': '₹250.00',
      'sellingPrice': '₹199.00',
      'grandTotal': '₹199.00',
      'paid': '₹199.00',
    };
  }

  Widget _buildOrderNumberCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteConstants.transactionDetails,
          arguments: {
            'title': 'Order Details',
            'transaction': _getResolvedTransaction(),
          },
        );
      },
      child: Container(
        height: Responsive.h(52),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(14)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: Responsive.w(18),
                ),
                SizedBox(width: Responsive.w(8)),
                CustomText.title(
                  'Order #$_orderId',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            Row(
              children: [
                CustomText.subtitle(
                  'View Details',
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(width: Responsive.w(4)),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return GestureDetector(
      onTap: () => _showNeedHelpBottomSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(16)),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: Responsive.w(1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(Responsive.w(16)),
        child: Row(
          children: [
            Container(
              width: Responsive.w(40),
              height: Responsive.w(40),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                color: AppColors.primary,
                size: Responsive.w(22),
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.title(
                    'Need help with your order?',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Responsive.h(2)),
                  CustomText.subtitle(
                    'Support, issue resolution & cancellations',
                    fontSize: 10,
                    color: AppColors.grayFont,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(12),
                vertical: Responsive.h(6),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(Responsive.w(16)),
              ),
              child: CustomText.title(
                'Get Help',
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNeedHelpBottomSheet(BuildContext context) {
    final tx = _getResolvedTransaction();
    final String storeName = tx['title']?.toString() ?? 'Store Order';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Responsive.w(28)),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            Responsive.w(20),
            Responsive.h(12),
            Responsive.w(20),
            MediaQuery.of(sheetCtx).viewInsets.bottom + Responsive.h(28),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag pill
                Center(
                  child: Container(
                    width: Responsive.w(44),
                    height: Responsive.h(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(Responsive.w(2)),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(16)),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText.header(
                          'Order Help & Support',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Responsive.h(2)),
                        CustomText.subtitle(
                          '$storeName · #$_orderId',
                          fontSize: 12,
                          color: AppColors.grayFont,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(16)),

                // 3 Quick Action Cards
                Row(
                  children: [
                    // Chat with support
                    Expanded(
                      child: _buildQuickHelpAction(
                        icon: Icons.chat_outlined,
                        label: 'Chat Support',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          Navigator.of(context).pushNamed(
                            RouteConstants.riderChat,
                            arguments: 'Support Agent',
                          );
                        },
                      ),
                    ),
                    SizedBox(width: Responsive.w(10)),

                    // Call helpline
                    Expanded(
                      child: _buildQuickHelpAction(
                        icon: Icons.phone_in_talk_outlined,
                        label: 'Call Helpline',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _showCallHelplineDialog(context);
                        },
                      ),
                    ),
                    SizedBox(width: Responsive.w(10)),

                    // Cancel order
                    Expanded(
                      child: _buildQuickHelpAction(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel Order',
                        color: const Color(0xFFD32F2F),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _showCancelOrderDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(20)),

                // Report an Issue Header
                CustomText.title(
                  'Report an Issue',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Responsive.h(4)),
                CustomText.subtitle(
                  'Select any problem with your order for instant assistance',
                  fontSize: 11,
                  color: AppColors.grayFont,
                ),
                SizedBox(height: Responsive.h(12)),

                // Issue options list
                ...[
                  {'icon': Icons.inventory_2_outlined, 'title': 'Missing or incorrect items'},
                  {'icon': Icons.access_time_outlined, 'title': 'Delivery delayed significantly'},
                  {'icon': Icons.broken_image_outlined, 'title': 'Items damaged or poor quality'},
                  {'icon': Icons.two_wheeler_outlined, 'title': 'Rider unreachable / delivery concern'},
                  {'icon': Icons.credit_card_outlined, 'title': 'Incorrect bill or payment issue'},
                ].map((issue) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: Responsive.h(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showReportIssueForm(context, issue['title'] as String);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(14),
                          vertical: Responsive.h(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                          border: Border.all(color: AppColors.outliner, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              issue['icon'] as IconData,
                              color: AppColors.primary,
                              size: Responsive.w(20),
                            ),
                            SizedBox(width: Responsive.w(12)),
                            Expanded(
                              child: CustomText.title(
                                issue['title'] as String,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: Responsive.h(16)),

                // Helpful FAQs
                CustomText.title(
                  'Frequently Asked Questions',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Responsive.h(10)),
                _buildFaqTile(
                  question: 'Can I change my delivery address?',
                  answer: 'If the rider hasn\'t picked up your items yet, please tap "Chat Support" to inform the dispatch team with your new address.',
                ),
                _buildFaqTile(
                  question: 'How do order cancellations work?',
                  answer: 'You can cancel free of charge before the merchant packs your order. The full payment is refunded immediately to your wallet.',
                ),
                _buildFaqTile(
                  question: 'Where is my delivery partner?',
                  answer: 'Track your rider in real time on the live map above as soon as your items are picked up from the merchant.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickHelpAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Responsive.w(14)),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: Responsive.w(22)),
            SizedBox(height: Responsive.h(6)),
            CustomText.title(
              label,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(8)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(12)),
        border: Border.all(color: AppColors.outliner, width: 1.0),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: Responsive.w(12)),
        childrenPadding: EdgeInsets.fromLTRB(
          Responsive.w(12),
          0,
          Responsive.w(12),
          Responsive.h(10),
        ),
        title: CustomText.title(
          question,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          CustomText.subtitle(
            answer,
            fontSize: 11,
            color: AppColors.grayFont,
            height: 1.4,
          ),
        ],
      ),
    );
  }

  void _showCallHelplineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(20)),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.w(8)),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk, color: Color(0xFF2E7D32)),
              ),
              SizedBox(width: Responsive.w(10)),
              CustomText.header('Call Support', fontSize: 16, fontWeight: FontWeight.bold),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.body(
                'Connect directly with our 24/7 Citizen & Order Helpline:',
                fontSize: 13,
              ),
              SizedBox(height: Responsive.h(12)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.w(12)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(Responsive.w(10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title('Toll-Free Helpline', fontSize: 11, color: Colors.grey.shade600),
                    SizedBox(height: Responsive.h(2)),
                    CustomText.header('1800-GOV-HELP (1800-468-4357)', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: CustomText.title('Close', color: AppColors.grayFont, fontSize: 13),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dialing Citizen Helpline 1800-GOV-HELP...'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
              child: CustomText.title('Dial Now', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  void _showCancelOrderDialog(BuildContext context) {
    String selectedReason = 'Placed by mistake';
    final List<String> reasons = [
      'Placed by mistake',
      'Delivery time is too long',
      'Need to modify items or address',
      'Other reason',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.w(20)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.w(8)),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFD32F2F)),
                  ),
                  SizedBox(width: Responsive.w(10)),
                  CustomText.header('Cancel Order?', fontSize: 16, fontWeight: FontWeight.bold),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.body(
                      'Are you sure you want to cancel order #$_orderId? 100% of the amount will be refunded directly to your wallet balance.',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(height: Responsive.h(14)),
                    CustomText.title('Reason for cancellation:', fontSize: 12, fontWeight: FontWeight.bold),
                    SizedBox(height: Responsive.h(6)),
                    ...reasons.map((r) {
                      final isSelected = selectedReason == r;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedReason = r;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: Responsive.h(6)),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(10),
                            vertical: Responsive.h(8),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF2EC) : Colors.transparent,
                            borderRadius: BorderRadius.circular(Responsive.w(8)),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.primary : Colors.grey,
                                size: Responsive.w(16),
                              ),
                              SizedBox(width: Responsive.w(8)),
                              Expanded(
                                child: CustomText.body(r, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: CustomText.title('Keep Order', color: AppColors.grayFont, fontSize: 13),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
                  ),
                  onPressed: () {
                    context.read<OrderTrackingBloc>().add(
                          CancelActiveOrderEvent(orderId: _orderId, reason: selectedReason),
                        );
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order #$_orderId cancelled. Refund credited to your wallet!'),
                        backgroundColor: const Color(0xFFD32F2F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
                      ),
                    );
                  },
                  child: CustomText.title('Confirm Cancel', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportIssueForm(BuildContext context, String issueTitle) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(20)),
          ),
          title: CustomText.header('Report Issue', fontSize: 16, fontWeight: FontWeight.bold),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(6)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EC),
                    borderRadius: BorderRadius.circular(Responsive.w(8)),
                  ),
                  child: CustomText.title(
                    issueTitle,
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
                CustomText.body(
                  'Please provide any details about what went wrong:',
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                SizedBox(height: Responsive.h(8)),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(10)),
                      borderSide: const BorderSide(color: AppColors.outliner),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: CustomText.title('Cancel', color: AppColors.grayFont, fontSize: 13),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                final ticketNumber = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                showDialog(
                  context: context,
                  builder: (confirmCtx) {
                    return AlertDialog(
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(20))),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.w(12)),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 36),
                          ),
                          SizedBox(height: Responsive.h(12)),
                          CustomText.header('Ticket #TKT-$ticketNumber Created', fontSize: 16, fontWeight: FontWeight.bold),
                          SizedBox(height: Responsive.h(6)),
                          CustomText.body(
                            'Thank you for reporting. Our support desk has received your issue and will resolve it promptly.',
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                      actions: [
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
                            ),
                            onPressed: () => Navigator.pop(confirmCtx),
                            child: CustomText.title('Done', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: CustomText.title('Submit Ticket', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}

