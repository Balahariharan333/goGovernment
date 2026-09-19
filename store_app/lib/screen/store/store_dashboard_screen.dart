import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../bloc/store/store_bloc.dart';
import '../../bloc/store/store_event.dart';
import '../../bloc/store/store_state.dart';
import '../../constants/route_constants.dart';
import '../../model/store_model.dart';
import '../../service/socket_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class StoreDashboardScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDashboardScreen({
    super.key,
    required this.store,
  });

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  late StoreModel _store;
  StreamSubscription? _newOrderSub;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    context.read<ProductBloc>().add(LoadStoreProductsEvent(_store.storeId));

    // Connect to WebSocket for real-time order alerts
    StoreSocketService().subscribeToStore(_store.storeId);
    _newOrderSub = StoreSocketService().onNewOrder.listen((newOrder) {
      if (!mounted) return;
      final orderId = newOrder['orderId']?.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 New order #$orderId received! Open Order Queue to fulfill.'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: _openOrderQueue,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    super.dispose();
  }

  void _toggleOnline(bool val) {
    context.read<StoreBloc>().add(
      ToggleStoreOnlineEvent(storeId: _store.storeId, isOnline: val),
    );
  }

  void _openStoreDetails() {
    Navigator.pushNamed(
      context,
      RouteConstants.storeDetails,
      arguments: {'store': _store},
    );
  }

  void _openManageProducts() {
    Navigator.pushNamed(
      context,
      RouteConstants.manageProducts,
      arguments: {'store': _store},
    );
  }

  void _openOrderQueue() {
    Navigator.pushNamed(
      context,
      RouteConstants.orderQueue,
      arguments: {'store': _store},
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your merchant portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.of(context).pushNamedAndRemoveUntil(RouteConstants.login, (r) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return BlocListener<StoreBloc, StoreState>(
      listener: (context, state) {
        if (state is StoreLoaded) {
          setState(() => _store = state.store);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.screenColor,
        appBar: AppBar(
          backgroundColor: AppColors.screenColor,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.only(left: Responsive.w(16)),
            child: GestureDetector(
              onTap: _openStoreDetails,
              child: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: _openStoreDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.title(_store.name, fontSize: 16, color: AppColors.black),
                CustomText.body(
                  'ID: ${_store.storeId} • ${_store.category.toUpperCase()}',
                  fontSize: 11,
                  color: AppColors.grayFont,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.black),
              tooltip: 'Store Details',
              onPressed: _openStoreDetails,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.black),
              onPressed: _logout,
            ),
          ],
        ),
        body: CommonBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(20), vertical: Responsive.h(12)),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online Status Banner
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.w(18), vertical: Responsive.h(14)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(18)),
                      border: Border.all(
                        color: _store.isOnline ? const Color(0xFF16A34A).withValues(alpha: 0.4) : AppColors.outliner,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _store.isOnline ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText.title(
                                _store.isOnline ? 'Store is OPEN for Citizens' : 'Store is OFFLINE',
                                fontSize: 14,
                                color: _store.isOnline ? const Color(0xFF16A34A) : AppColors.grayFont,
                              ),
                              CustomText.body(
                                _store.isOnline
                                    ? 'Nearby users can place subsidy orders'
                                    : 'Store is currently hidden on citizen app',
                                fontSize: 11,
                                color: AppColors.grayFont,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _store.isOnline,
                          activeThumbColor: const Color(0xFF16A34A),
                          onChanged: _toggleOnline,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),

                  // Performance KPIs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _openOrderQueue,
                          child: _buildMetricCard('Today\'s Orders', 'Live Queue', Icons.shopping_bag_outlined, const Color(0xFF2563EB)),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      Expanded(child: _buildMetricCard('Subsidies Claimed', '₹4,820', Icons.currency_rupee_rounded, AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: Responsive.h(12)),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Citizen Rating', '★ ${_store.rating.toStringAsFixed(1)}', Icons.star_rounded, const Color(0xFFD97706))),
                      SizedBox(width: Responsive.w(12)),
                      Expanded(
                        child: BlocBuilder<ProductBloc, ProductState>(
                          builder: (context, pState) {
                            String countStr = '0 Items';
                            if (pState is ProductLoaded) {
                              countStr = '${pState.products.length} Items';
                            }
                            return GestureDetector(
                              onTap: _openManageProducts,
                              child: _buildMetricCard(
                                'Active Products',
                                countStr,
                                Icons.inventory_2_outlined,
                                const Color(0xFF16A34A),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(24)),

                  // Quick Action Tiles
                  CustomText.title('Merchant Operations', fontSize: 15, color: AppColors.black),
                  SizedBox(height: Responsive.h(12)),
                  _buildActionTile(
                    Icons.storefront_rounded,
                    'Store Profile & Verification Details',
                    'View municipal certificate, address & category',
                    onTap: _openStoreDetails,
                  ),
                  _buildActionTile(
                    Icons.inventory_rounded,
                    'Stock & Commodities Inventory',
                    'Add & manage catalog products & stock counts',
                    onTap: _openManageProducts,
                  ),
                  _buildActionTile(
                    Icons.receipt_long_rounded,
                    'Order Processing Queue',
                    'View and fulfill incoming citizen orders',
                    onTap: _openOrderQueue,
                  ),
                  _buildActionTile(
                    Icons.account_balance_rounded,
                    'Settlement Bank Account',
                    '${_store.bankDetails.bankName.isNotEmpty ? _store.bankDetails.bankName : 'Configured'} (IFSC: ${_store.bankDetails.ifscCode})',
                    onTap: _openStoreDetails,
                  ),
                  _buildActionTile(
                    Icons.access_time_rounded,
                    'Operating Hours & Holidays',
                    '${_store.timings['open'] ?? '08:00 AM'} - ${_store.timings['close'] ?? '08:30 PM'}',
                    onTap: _openStoreDetails,
                  ),
                  SizedBox(height: Responsive.h(24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.w(18)),
        border: Border.all(color: AppColors.outliner.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText.body(label, fontSize: 11, color: AppColors.grayFont),
              Icon(icon, size: 18, color: color),
            ],
          ),
          SizedBox(height: Responsive.h(8)),
          CustomText.header(value, fontSize: 18, color: AppColors.black),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.h(10)),
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(16), vertical: Responsive.h(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.w(16)),
          border: Border.all(color: AppColors.outliner.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.w(8)),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.w(10)),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            SizedBox(width: Responsive.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.title(title, fontSize: 13, color: AppColors.black),
                  SizedBox(height: Responsive.h(2)),
                  CustomText.body(subtitle, fontSize: 11, color: AppColors.grayFont),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grayFont),
          ],
        ),
      ),
    );
  }
}
