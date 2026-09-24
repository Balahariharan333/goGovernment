import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';
import '../../hive/hive_service.dart';
import '../../model/delivery_order_model.dart';
import '../../network/rider_api_service.dart';
import '../../constants/route_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../widget/rider_bottom_nav_bar.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  Map<String, dynamic>? _walletData;
  bool _isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(LoadDeliveriesEvent());
    _fetchLiveWallet();
  }

  Future<void> _fetchLiveWallet() async {
    final userId = HiveService.userId;
    if (userId.isEmpty) return;
    setState(() => _isLoadingWallet = true);
    try {
      final res = await RiderApiService.fetchRiderWallet(userId);
      if (mounted && res != null) {
        setState(() {
          _walletData = res;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingWallet = false);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, RouteConstants.dashboard, (route) => false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: CustomText.title('Earnings & Payouts', fontWeight: FontWeight.bold),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, RouteConstants.dashboard, (route) => false);
              }
            },
          ),
        actions: [
          IconButton(
            icon: _isLoadingWallet
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.black),
            onPressed: _isLoadingWallet ? null : _fetchLiveWallet,
          ),
        ],
      ),
      body: CommonBackground(
        child: SafeArea(
          child: BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, state) {
              final backendBalance = (_walletData?['walletBalance'] as num?)?.toDouble();
              final totalEarnings = backendBalance ??
                  (state is DeliveryLoaded ? state.totalEarnings : HiveService.totalEarnings);

              final rawTxList = (_walletData?['transactions'] as List?) ?? [];
              final transactions = rawTxList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

              final completedOrders = state is DeliveryLoaded ? state.completedOrders : <DeliveryOrder>[];
              final completedCount = completedOrders.isNotEmpty
                  ? completedOrders.length
                  : (transactions.isNotEmpty ? transactions.length : (state is DeliveryLoaded ? state.completedCount : HiveService.completedCount));

              final displayRecordsCount = completedOrders.isNotEmpty ? completedOrders.length : transactions.length;

              return RefreshIndicator(
                onRefresh: _fetchLiveWallet,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.all(Responsive.w(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big Earnings Hero Card
                      _buildEarningsCard(totalEarnings, completedCount),
                      SizedBox(height: Responsive.h(20)),

                      // Payout Schedule Card
                      _buildPayoutScheduleCard(context),
                      SizedBox(height: Responsive.h(24)),

                      // Completed Deliveries History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText.title(
                            'Completed Deliveries History',
                            fontSize: Responsive.sp(16),
                            fontWeight: FontWeight.bold,
                          ),
                          CustomText.caption(
                            '$displayRecordsCount records',
                            color: AppColors.grayFont,
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(12)),

                      if (completedOrders.isNotEmpty)
                        ...completedOrders.map((order) => _buildOrderHistoryItem(order))
                      else if (transactions.isNotEmpty)
                        ...transactions.map((tx) => _buildTransactionItem(tx))
                      else
                        _buildEmptyHistory(),

                      SizedBox(height: Responsive.h(30)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const RiderBottomNavBar(currentIndex: 1),
    ),
  );
}

  Widget _buildEarningsCard(double total, int trips) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Deep professional navy-blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: CustomText.caption(
                  'TOTAL BALANCE PAYABLE',
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(8), vertical: Responsive.h(3)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Bank Transfer', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: Responsive.sp(34),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.h(14)),
          const Divider(color: Colors.white24, height: 1),
          SizedBox(height: Responsive.h(14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statMini('Delivered Orders', '$trips trips'),
              _statMini('Avg / Trip', trips > 0 ? '₹${(total / trips).toStringAsFixed(0)}' : '₹0'),
              _statMini('Incentive', trips >= 10 ? '₹100 Bonus' : (trips >= 5 ? '₹50 Bonus' : '₹0 Bonus')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMini(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText.caption(title, color: Colors.white60, fontSize: Responsive.sp(11)),
        SizedBox(height: Responsive.h(2)),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildPayoutScheduleCard(BuildContext context) {
    final phone = HiveService.userPhone;
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, color: AppColors.primary),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title('Payout Account Linked', fontSize: Responsive.sp(14)),
                    CustomText.caption(
                      phone.isNotEmpty ? 'Direct Deposit / UPI · $phone' : 'Direct Bank Settlement (Auto-processed)',
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: AppColors.success, size: 20),
            ],
          ),
          SizedBox(height: Responsive.h(14)),
          SizedBox(
            width: double.infinity,
            height: Responsive.h(42),
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weekly payout is auto-settled every Monday to your linked bank account.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(10))),
              ),
              child: const Text('View Settlement Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
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
          const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.grayFont),
          SizedBox(height: Responsive.h(10)),
          CustomText.title('No Completed Deliveries Yet', fontSize: Responsive.sp(14)),
          SizedBox(height: Responsive.h(4)),
          CustomText.caption('Accepted orders completed by you will be listed here with individual earnings.'),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryItem(DeliveryOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(10)),
      padding: EdgeInsets.all(Responsive.w(14)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.w(18),
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.title(order.storeName, fontSize: Responsive.sp(13)),
                CustomText.caption(
                  'Delivered to ${order.receiverName} · #${order.orderId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText.title('+₹${order.estimatedPayout.toStringAsFixed(0)}', fontSize: Responsive.sp(14), color: AppColors.success, fontWeight: FontWeight.bold),
              CustomText.caption('Delivered', color: AppColors.grayFont, fontSize: Responsive.sp(11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 45.0;
    final desc = tx['description']?.toString() ?? 'Order Delivery Payout';
    final ref = tx['referenceId']?.toString() ?? '';
    final date = tx['createdAt']?.toString();
    String dateStr = '';
    if (date != null && date.isNotEmpty) {
      final dt = DateTime.tryParse(date)?.toLocal();
      if (dt != null) {
        final m = dt.minute.toString().padLeft(2, '0');
        dateStr = '${dt.day}/${dt.month} ${dt.hour}:$m';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(10)),
      padding: EdgeInsets.all(Responsive.w(14)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.w(18),
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.title(desc, fontSize: Responsive.sp(13)),
                CustomText.caption(
                  '${ref.isNotEmpty ? '#$ref · ' : ''}${dateStr.isNotEmpty ? dateStr : 'Credited to Wallet'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText.title(
                '+₹${amount.toStringAsFixed(0)}',
                fontSize: Responsive.sp(14),
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              CustomText.caption('Credited', color: AppColors.grayFont, fontSize: Responsive.sp(11)),
            ],
          ),
        ],
      ),
    );
  }
}
