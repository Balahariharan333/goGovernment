import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../constants/route_constants.dart';
import '../../network/order_api_service.dart';
import '../../service/socket_service.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';
import '../../service/cart_manager.dart';
import '../../utils/call_launcher.dart';

class YourOrdersScreen extends StatefulWidget {
  const YourOrdersScreen({super.key});

  @override
  State<YourOrdersScreen> createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  String _selectedFilter = 'All'; // 'All', 'Active', 'Completed'
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();

    // Listen to real-time status updates without battery drain
    _socketSub = SocketService().onOrderStatusUpdate.listen((_) {
      if (mounted) {
        _fetchLiveOrders();
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveOrders() async {
    try {
      final serverOrders = await OrderApiService.fetchUserOrders();
      if (!mounted || serverOrders.isEmpty) return;

      final currentTxs = context.read<TransactionBloc>().state.transactions;

      for (final order in serverOrders) {
        final orderId = order['orderId']?.toString();
        if (orderId == null || orderId.isEmpty) continue;

        final rawStatus = order['status']?.toString() ?? 'placed';
        String displayStatus = 'Processing';
        if (rawStatus == 'placed') displayStatus = 'Placed';
        if (rawStatus == 'preparing') displayStatus = 'Preparing';
        if (rawStatus == 'ready_for_pickup') displayStatus = 'Ready for Pickup';
        if (rawStatus == 'out_for_delivery') displayStatus = 'Out for Delivery';
        if (rawStatus == 'delivered') displayStatus = 'Delivered';
        if (rawStatus == 'cancelled') displayStatus = 'Cancelled';

        final existingIdx = currentTxs.indexWhere((tx) => tx['id']?.toString() == orderId);
        if (existingIdx != -1) {
          if (currentTxs[existingIdx]['status'] != displayStatus) {
            context.read<TransactionBloc>().add(
              UpdateOrderStatusEvent(orderId: orderId, status: displayStatus),
            );
          }
        } else {
          final storeDetails = order['storeDetails'] as Map? ?? {};
          final storeName = storeDetails['name']?.toString() ?? 'Government Store';
          final grandTotal = order['grandTotal']?.toString() ?? '0';
          final items = (order['items'] as List?) ?? [];

          final tx = {
            'id': orderId,
            'title': storeName,
            'subtitle': 'Order placed',
            'amount': '-₹$grandTotal',
            'isPositive': false,
            'status': displayStatus,
            'date': 'Recent',
            'items': items,
            'address': order['deliveryAddress']?['address']?.toString() ?? '',
            'listingPrice': '₹$grandTotal',
            'sellingPrice': '₹$grandTotal',
            'grandTotal': '₹$grandTotal',
            'paid': '₹$grandTotal',
            'storeDetails': storeDetails,
            'storePhone': (storeDetails['phone'] ?? '').toString(),
          };
          context.read<TransactionBloc>().add(AddTransactionEvent(tx));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: Responsive.w(70),
        leading: Padding(
          padding: EdgeInsets.only(left: Responsive.w(20)),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: Responsive.w(44),
                height: Responsive.w(44),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outliner,
                    width: Responsive.w(1.5),
                  ),
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: AppColors.black,
                  size: Responsive.w(24),
                ),
              ),
            ),
          ),
        ),
        title: CustomText.header(
          'Your Orders',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final rawTransactions = state.transactions;

              // Filter to store orders only (has items or starts with ORD-)
              final allOrders = rawTransactions.where((tx) {
                final List items = (tx['items'] as List?) ?? [];
                final String id = tx['id']?.toString() ?? '';
                return items.isNotEmpty || id.startsWith('ORD-');
              }).toList();

              // Apply status filter
              final filteredOrders = allOrders.where((order) {
                if (_selectedFilter == 'All') return true;
                final status = (order['status']?.toString() ?? '')
                    .toLowerCase();
                final isEnded =
                    status.contains('delivered') ||
                    status.contains('completed') ||
                    status.contains('cancel') ||
                    status.contains('refund') ||
                    status.contains('fail');
                final isActive = !isEnded;
                if (_selectedFilter == 'Active') return isActive;
                if (_selectedFilter == 'Completed') return isEnded;
                return true;
              }).toList();

              return Column(
                children: [
                  // Filter Chips
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(20),
                      vertical: Responsive.h(8),
                    ),
                    child: Row(
                      children: ['All', 'Active', 'Completed'].map((filter) {
                        final bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: EdgeInsets.only(right: Responsive.w(8)),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.w(16),
                                vertical: Responsive.h(6),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  Responsive.w(20),
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outliner,
                                  width: 1.2,
                                ),
                              ),
                              child: CustomText.title(
                                filter,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.grayFont,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Order List or Empty State
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _fetchLiveOrders,
                            color: AppColors.primary,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: _buildEmptyState(context),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchLiveOrders,
                            color: AppColors.primary,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                Responsive.w(20),
                                Responsive.h(8),
                                Responsive.w(20),
                                Responsive.h(40),
                              ),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: Responsive.h(14),
                                  ),
                                  child: _buildOrderCard(context, order),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Responsive.w(84),
              height: Responsive.w(84),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: Responsive.w(44),
              ),
            ),
            SizedBox(height: Responsive.h(20)),
            CustomText.header(
              'No ${_selectedFilter == 'All' ? '' : '$_selectedFilter '}Orders Found',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: Responsive.h(8)),
            CustomText.subtitle(
              'When you place an order from our verified government stores, you can track it live right here.',
              fontSize: 13,
              color: AppColors.grayFont,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.h(24)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(24),
                  vertical: Responsive.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.w(20)),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(RouteConstants.nearStores);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: Responsive.w(8)),
                  CustomText.title(
                    'Explore Stores',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final String id = order['id']?.toString() ?? 'ORD-0000';
    final String storeName = order['title']?.toString() ?? 'Government Store';
    final String date = order['date']?.toString() ?? 'Recent';
    final String amount = order['amount']?.toString() ?? '₹0';
    final String status = order['status']?.toString() ?? 'Processing';
    final List items = (order['items'] as List?) ?? [];
    final String storePhone = (order['storePhone'] ??
            (order['storeDetails'] is Map ? order['storeDetails']['phone'] : null) ??
            '')
        .toString();

    final String s = status.toLowerCase();
    final bool isDelivered = s.contains('delivered') || s.contains('completed');
    final bool isCancelled =
        s.contains('cancel') || s.contains('refund') || s.contains('fail');
    final bool isActive = !isDelivered && !isCancelled;

    final Color statusColor = isDelivered
        ? const Color(0xFF2E7D32)
        : (isCancelled ? const Color(0xFFD32F2F) : const Color(0xFFE65100));
    final Color statusBg = isDelivered
        ? const Color(0xFFE8F5E9)
        : (isCancelled ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0));

    // Summary of items
    String itemsText = '';
    if (items.isNotEmpty) {
      final names = items
          .map((it) {
            if (it is Map) {
              final title = it['title']?.toString() ?? 'Item';
              final qty = it['qty'] ?? 1;
              return '$title (x$qty)';
            }
            return it.toString();
          })
          .take(3)
          .toList();
      itemsText = names.join(', ');
      if (items.length > 3) {
        itemsText += ' +${items.length - 3} more';
      }
    } else {
      itemsText = order['subtitle']?.toString() ?? 'Store items';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        border: Border.all(color: AppColors.outliner, width: Responsive.w(1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(Responsive.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: Responsive.w(36),
                      height: Responsive.w(36),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2EC),
                        borderRadius: BorderRadius.circular(Responsive.w(10)),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: AppColors.primary,
                        size: Responsive.w(18),
                      ),
                    ),
                    SizedBox(width: Responsive.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText.title(
                            storeName,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          CustomText.subtitle(
                            date,
                            fontSize: 11,
                            color: AppColors.grayFont,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(10),
                  vertical: Responsive.h(4),
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(Responsive.w(10)),
                ),
                child: CustomText.title(
                  status,
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          const Divider(height: 1),
          SizedBox(height: Responsive.h(12)),

          // Items summary & order ID
          CustomText.subtitle(
            'Order #$id',
            fontSize: 11,
            color: AppColors.grayFont,
          ),
          SizedBox(height: Responsive.h(4)),
          CustomText.body(
            itemsText,
            fontSize: 12,
            color: Colors.grey.shade800,
            maxLines: 2,
          ),
          SizedBox(height: Responsive.h(12)),

          // Price & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.subtitle(
                    'Total Paid',
                    fontSize: 10,
                    color: AppColors.grayFont,
                  ),
                  CustomText.title(
                    amount.replaceAll('-', ''),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ],
              ),
              Row(
                children: [
                  // Track Order button (strictly for active orders)
                  if (isActive) ...[

                    // Track Order button (strictly for active orders)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.orderStatus,
                          arguments: {
                            'storeType': 'medical',
                            'orderId': id,
                            'transaction': order,
                          },
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: Responsive.w(8)),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(12),
                          vertical: Responsive.h(8),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(Responsive.w(16)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.navigation_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: Responsive.w(4)),
                            CustomText.title(
                              'Track',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Call Store button (if store phone is available)
                  if (storePhone.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => CallLauncher.launchCall(
                        context,
                        phone: storePhone,
                        name: storeName,
                      ),
                      child: Container(
                        margin: EdgeInsets.only(right: Responsive.w(8)),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(10),
                          vertical: Responsive.h(8),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(Responsive.w(16)),
                          border: Border.all(
                            color: Colors.green.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF2E7D32),
                              size: 13,
                            ),
                            SizedBox(width: Responsive.w(4)),
                            CustomText.title(
                              'Call',
                              color: const Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Reorder button (instant 1-tap reorder directly to Cart)
                  GestureDetector(
                    onTap: () => _reorderOrderAndGoToCart(context, order),
                    child: Container(
                      margin: EdgeInsets.only(right: Responsive.w(8)),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(12),
                        vertical: Responsive.h(8),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2EC),
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.replay,
                            color: AppColors.primary,
                            size: 13,
                          ),
                          SizedBox(width: Responsive.w(4)),
                          CustomText.title(
                            'Reorder',
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // View Details button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        RouteConstants.transactionDetails,
                        arguments: {'title': storeName, 'transaction': order},
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(14),
                        vertical: Responsive.h(8),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                        border: Border.all(
                          color: AppColors.outliner,
                          width: 1.2,
                        ),
                      ),
                      child: CustomText.title(
                        'Details',
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reorderOrderAndGoToCart(BuildContext context, Map<String, dynamic> order) {
    final List items = (order['items'] as List?) ?? [];
    if (items.isNotEmpty) {
      for (final raw in items) {
        if (raw is Map) {
          final it = Map<String, dynamic>.from(raw);
          final pId = it['productId']?.toString() ??
              it['id']?.toString() ??
              'prod_${DateTime.now().millisecondsSinceEpoch}';
          final prodData = {
            ...it,
            'id': pId,
            'productId': pId,
            'title': it['title'] ?? it['name'] ?? 'Product',
            'price': it['price'] ?? 99,
            'originalPrice': it['originalPrice'] ?? it['price'] ?? 99,
            'image': it['image'] ?? it['imageUrl'] ?? 'assets/images/product1.png',
            'stock': 10,
          };
          final qty = ((it['qty'] ?? it['quantity'] ?? 1) as num).toInt();
          CartManager.instance.addToCart(prodData, qty: qty);
        }
      }
    } else {
      CartManager.instance.addToCart({
        'id': 'reorder_${DateTime.now().millisecondsSinceEpoch}',
        'title': order['title'] ?? 'Store Item',
        'price': 99,
        'originalPrice': 150,
        'image': 'assets/images/product1.png',
        'stock': 10,
      }, qty: 1);
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reordered ${items.isNotEmpty ? items.length : 1} item(s)! Navigating to cart...'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, RouteConstants.cart),
        ),
      ),
    );

    Navigator.of(context).pushNamed(RouteConstants.cart);
  }
}
