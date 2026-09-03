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

class OrderStatusScreen extends StatefulWidget {
  final String storeType;

  const OrderStatusScreen({
    super.key,
    required this.storeType,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {

  int get _currentStep => context.read<OrderTrackingBloc>().state.currentStep;

  final String _receiverName = 'Suriya';
  String _receiverPhone = '+91 1234509876';
  String _deliveryAddress = '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102';

  @override
  void initState() {
    super.initState();
    final initialAddr = context.read<AddressBloc>().state.selectedAddress;
    if (initialAddr != null) {
      _deliveryAddress = initialAddr.description;
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
                        // TODO: Remove after API is connected — manual step tester
                        Container(
                          height: Responsive.h(36),
                          margin: EdgeInsets.only(bottom: Responsive.h(16)),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              final bool isActive = currentStep == index;
                              return Padding(
                                padding: EdgeInsets.only(right: Responsive.w(8)),
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<OrderTrackingBloc>().add(UpdateTrackingStepEvent(index));
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
                                        'Stage ${index + 1}',
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
                  Navigator.pop(context);
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
                          'Massage', // spelling matching mockup
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

  Widget _buildOrderNumberCard() {
    return Container(
      height: Responsive.h(50),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(14)),
        border: Border.all(
          color: AppColors.outliner,
          width: Responsive.w(1.2),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.grey,
                size: Responsive.w(16),
              ),
              SizedBox(width: Responsive.w(8)),
              CustomText.title(
                'Order #123456787654',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(
          color: AppColors.outliner,
          width: Responsive.w(1.2),
        ),
      ),
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Row(
        children: [
          Container(
            width: Responsive.w(38),
            height: Responsive.w(38),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.title(
                  'Need help with your order?',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Responsive.h(2)),
                const Text(
                  'Get help & support',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
