import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';
import '../../service/cart_manager.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.title,
    this.transaction,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  void _showReturnDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(20)),
          ),
          title: CustomText.header('Confirm Return', fontSize: 16, fontWeight: FontWeight.bold),
          content: CustomText.body('Are you sure you want to return this product?', fontSize: 13),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: CustomText.title('Cancel', color: AppColors.grayFont, fontSize: 13),
            ),
            TextButton(
              onPressed: () {
                context.read<TransactionBloc>().add(ReturnWatermelonProductEvent(index));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Return processed successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                  ),
                );
              },
              child: CustomText.title('Confirm', color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final bool showReorderScreen = state.showReorderScreen;
        final List<bool> watermelonReturned = state.watermelonReturned;

        final tx = widget.transaction != null
            ? Map<String, dynamic>.from(widget.transaction!)
            : <String, dynamic>{};
        final String orderId = tx['id']?.toString() ?? 'TX-ERTYUIOP09876';
        final String title = tx['title']?.toString() ?? 'Transaction';
        final String amount = tx['amount']?.toString() ?? '0';
        final List items = (tx['items'] as List?) ?? [];
        final String listingPrice = tx['listingPrice']?.toString() ?? '₹225.00';
        final String sellingPrice = tx['sellingPrice']?.toString() ?? '₹99.50';
        final String grandTotal = tx['grandTotal']?.toString() ?? '₹99.50';
        final String paid = tx['paid']?.toString() ?? '₹100.00';

        final bool isStoreOrder = items.isNotEmpty || orderId.startsWith('ORD-');
        final bool isCoinsReward = title.toLowerCase().contains('coin') ||
            title.toLowerCase().contains('bonus') ||
            title.toLowerCase().contains('reward') ||
            title.toLowerCase().contains('complaint') ||
            title.toLowerCase().contains('survey') ||
            !amount.contains('₹');
        final bool isWalletTx = title.toLowerCase().contains('wallet');

        String screenTitle = 'Order Details';
        if (showReorderScreen) {
          screenTitle = 'Reorder Items';
        } else if (!isStoreOrder) {
          if (isCoinsReward) {
            screenTitle = 'Reward Details';
          } else if (isWalletTx) {
            screenTitle = 'Wallet Details';
          } else {
            screenTitle = 'Transaction Details';
          }
        }

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
                  onTap: () {
                    if (showReorderScreen) {
                      context.read<TransactionBloc>().add(ToggleReorderScreenEvent(false));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: Responsive.w(44),
                    height: Responsive.w(44),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
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
              screenTitle,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            centerTitle: false,
          ),
          body: CommonBackground(
            child: SafeArea(
              bottom: false,
              child: !isStoreOrder
                  ? _buildRewardOrWalletDetailsView(context, tx)
                  : (showReorderScreen
                      ? _buildReorderView(context)
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(20),
                              vertical: Responsive.h(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order ID
                                CustomText.subtitle(
                                  'Order ID - $orderId',
                                  fontSize: 13,
                                  color: AppColors.grayFont,
                                ),
                                SizedBox(height: Responsive.h(16)),

                                // Items card — orange border
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(Responsive.w(20)),
                                    border: Border.all(
                                      color: AppColors.outliner,
                                      width: Responsive.w(1.5),
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.w(16),
                                    vertical: Responsive.h(8),
                                  ),
                                  child: Column(
                                    children: items.asMap().entries.map((e) {
                                      final int idx = e.key;
                                      final it = Map<String, dynamic>.from(e.value as Map);
                                      final isRet = idx < watermelonReturned.length ? watermelonReturned[idx] : false;
                                      return _buildItemRow(
                                        context,
                                        idx,
                                        it['title'] ?? 'Product',
                                        '${it['price'] ?? '₹ 99.0'} x ${it['qty'] ?? 1}',
                                        it['image'] ?? 'assets/images/product1.png',
                                        isRet,
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(height: Responsive.h(16)),

                                // Bill Summary card — orange border
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(Responsive.w(20)),
                                    border: Border.all(
                                      color: AppColors.outliner,
                                      width: Responsive.w(1.5),
                                    ),
                                  ),
                                  padding: EdgeInsets.all(Responsive.w(16)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: Responsive.w(36),
                                                height: Responsive.w(36),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF2EC),
                                                  borderRadius: BorderRadius.circular(Responsive.w(10)),
                                                ),
                                                child: Icon(
                                                  Icons.receipt_long_outlined,
                                                  color: AppColors.primary,
                                                  size: Responsive.w(20),
                                                ),
                                              ),
                                              SizedBox(width: Responsive.w(10)),
                                              CustomText.title(
                                                'Bill Summary',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: Responsive.w(36),
                                            height: Responsive.w(36),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE8F5E9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.download_outlined,
                                              color: Colors.green,
                                              size: Responsive.w(18),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: Responsive.h(14)),
                                      _buildPriceRow('Listing price', listingPrice, isGray: true),
                                      SizedBox(height: Responsive.h(8)),
                                      _buildPriceRow('Selling price', sellingPrice, isGray: true),
                                      SizedBox(height: Responsive.h(10)),
                                      _buildDivider(),
                                      SizedBox(height: Responsive.h(10)),
                                      _buildPriceRow('Grand total', grandTotal),
                                      SizedBox(height: Responsive.h(8)),
                                      _buildPriceRow('Coupon applied', '₹00.00', isGray: true),
                                      SizedBox(height: Responsive.h(8)),
                                      _buildPriceRow('Cash round off', '₹00.01', isGray: true),
                                      SizedBox(height: Responsive.h(8)),
                                      _buildPriceRow('Paid', paid, isBold: true),
                                    ],
                                  ),
                                ),
                                SizedBox(height: Responsive.h(24)),

                                // Reorder + Invoice buttons
                                _buildBottomButtons(context),
                                SizedBox(height: Responsive.h(40)),
                              ],
                            ),
                          ),
                        )),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardOrWalletDetailsView(BuildContext context, Map<String, dynamic> tx) {
    final String id = tx['id']?.toString() ?? 'TX-0000';
    final String title = tx['title']?.toString() ?? 'Civic Reward';
    final String subtitle = tx['subtitle']?.toString() ?? '';
    final String amount = tx['amount']?.toString() ?? '+100';
    final bool isPositive = tx['isPositive'] == true;
    final String status = tx['status']?.toString() ?? 'Credited';
    final String date = tx['date']?.toString() ?? 'Today';

    final bool isCoins = title.toLowerCase().contains('coin') ||
        title.toLowerCase().contains('bonus') ||
        title.toLowerCase().contains('reward') ||
        title.toLowerCase().contains('complaint') ||
        title.toLowerCase().contains('survey') ||
        !amount.contains('₹');

    String formattedAmount = amount;
    if (isCoins) {
      final String cleanAmt = amount.replaceAll('+', '').replaceAll('-', '').replaceAll('Coins', '').replaceAll('🪙', '').trim();
      formattedAmount = isPositive ? '+$cleanAmt Coins' : '-$cleanAmt Coins';
    } else {
      if (!formattedAmount.contains('₹')) {
        formattedAmount = isPositive ? '+₹$formattedAmount' : '-₹$formattedAmount';
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(20),
        vertical: Responsive.h(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Large Hero Credit Receipt Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(20),
              vertical: Responsive.h(24),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              border: Border.all(
                color: AppColors.outliner,
                width: Responsive.w(1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Icon badge
                Container(
                  width: Responsive.w(64),
                  height: Responsive.w(64),
                  decoration: BoxDecoration(
                    color: isCoins ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCoins ? Icons.monetization_on : Icons.account_balance_wallet_rounded,
                    color: isCoins ? const Color(0xFFFFB300) : const Color(0xFF43A047),
                    size: Responsive.w(36),
                  ),
                ),
                SizedBox(height: Responsive.h(16)),

                // Amount Text
                CustomText.header(
                  formattedAmount,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0xFF2E7D32) : AppColors.black,
                ),
                SizedBox(height: Responsive.h(6)),

                // Subtitle
                CustomText.title(
                  title,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                SizedBox(height: Responsive.h(4)),
                CustomText.subtitle(
                  subtitle,
                  fontSize: 12,
                  color: AppColors.grayFont,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.h(14)),

                // Status chip
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(14),
                    vertical: Responsive.h(5),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(Responsive.w(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                      SizedBox(width: Responsive.w(6)),
                      CustomText.title(
                        status,
                        color: const Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(16)),

          // 2. Transaction Details Breakdown Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.w(16)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Responsive.w(20)),
              border: Border.all(
                color: AppColors.outliner,
                width: Responsive.w(1.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: Responsive.w(18)),
                    SizedBox(width: Responsive.w(8)),
                    CustomText.title('Transaction Information', fontSize: 14, fontWeight: FontWeight.bold),
                  ],
                ),
                SizedBox(height: Responsive.h(14)),
                _buildPriceRow('Transaction ID', id, isGray: true),
                SizedBox(height: Responsive.h(10)),
                _buildPriceRow('Activity Type', isCoins ? 'Civic Reward' : 'Wallet Credit', isGray: true),
                SizedBox(height: Responsive.h(10)),
                _buildPriceRow('Date & Time', date, isGray: true),
                SizedBox(height: Responsive.h(10)),
                _buildPriceRow('Program', 'GoGovernment Civic Rewards', isGray: true),
                SizedBox(height: Responsive.h(12)),
                _buildDivider(),
                SizedBox(height: Responsive.h(12)),
                _buildPriceRow('Credited Account', isCoins ? 'Complaint Coins Balance' : 'GoGov Wallet Balance', isBold: true),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(16)),

          // 3. Helpful Info Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.w(14)),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(Responsive.w(16)),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: Responsive.w(10)),
                Expanded(
                  child: CustomText.subtitle(
                    isCoins
                        ? 'Complaint Coins can be redeemed directly for real wallet cash anytime (100 Coins = ₹1, min 100 coins) or applied during store checkout for extra savings.'
                        : 'Your GoGov Wallet balance can be used directly for seamless 1-click purchases in local stores.',
                    fontSize: 11,
                    color: const Color(0xFF2E7D32),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(24)),

          // 4. Return to Transactions button
          SizedBox(
            width: double.infinity,
            height: Responsive.h(48),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.w(24)),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: CustomText.title(
                'Back to Transactions',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: Responsive.h(20)),
        ],
      ),
    );
  }

  Widget _buildReorderView(BuildContext context) {
    final List items = widget.transaction?['items'] as List? ?? [];
    final hasItems = items.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(20),
        vertical: Responsive.h(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.title(
            'Reorder products from this transaction. Select items to add back to your active cart.',
            fontSize: 13,
            color: AppColors.grayFont,
          ),
          SizedBox(height: Responsive.h(20)),
          if (hasItems) ...[
            ...items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              final String title = item['title'] ?? 'Product';
              final String price = item['price'] ?? '₹99';
              final int qty = (item['qty'] as num?)?.toInt() ?? 1;
              return Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(12)),
                child: _buildReorderCard(
                  context,
                  title,
                  '$price x $qty qty',
                  '$qty items will be added to cart',
                  true,
                  item: item,
                ),
              );
            }),
          ] else ...[
            _buildReorderCard(context, 'Watermelon striped', '₹99 x 3 qty', '3 items will be added to cart', true),
            SizedBox(height: Responsive.h(12)),
            _buildReorderCard(context, 'Fresh Apple Red', '₹150 x 1 qty', 'Item is temporarily out of stock', false),
            SizedBox(height: Responsive.h(12)),
            _buildReorderCard(context, 'Fresh Spinach bunch', '₹25 x 2 qty', '2 items will be added to cart', true),
          ],
        ],
      ),
    );
  }

  Widget _buildReorderCard(
    BuildContext context,
    String title,
    String qtyText,
    String summary,
    bool isAvailable, {
    Map<String, dynamic>? item,
  }) {
    return Container(
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.w(8)),
                child: Image.asset(
                  item?['image'] ?? 'assets/images/product1.png',
                  width: Responsive.w(48),
                  height: Responsive.w(48),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title(
                      title,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(2)),
                    CustomText.subtitle(
                      qtyText,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(6)),
          CustomText.subtitle(
            summary,
            fontSize: 11,
            color: AppColors.grayFont,
          ),
          SizedBox(height: Responsive.h(12)),

          // Reorder or Not Available Action Button
          GestureDetector(
            onTap: isAvailable
                ? () {
                    if (item != null) {
                      CartManager.instance.addToCart(item, qty: item['qty'] ?? 1);
                    } else {
                      CartManager.instance.addToCart({
                        'id': 'reorder_${DateTime.now().millisecondsSinceEpoch}',
                        'title': title,
                        'price': 99,
                        'originalPrice': 150,
                        'image': 'assets/images/product1.png',
                      }, qty: 1);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title added to cart!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.read<TransactionBloc>().add(ToggleReorderScreenEvent(false));
                  }
                : null,
            child: Container(
              height: Responsive.h(40),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.transparent : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(Responsive.w(20)),
                border: Border.all(
                  color: isAvailable ? AppColors.primary : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAvailable) ...[
                      Icon(Icons.refresh, color: AppColors.primary, size: Responsive.w(16)),
                      SizedBox(width: Responsive.w(6)),
                    ] else ...[
                      Icon(Icons.block, color: Colors.grey.shade400, size: Responsive.w(16)),
                      SizedBox(width: Responsive.w(6)),
                    ],
                    CustomText.title(
                      isAvailable ? 'Reorder' : 'Not Available',
                      color: isAvailable ? AppColors.primary : Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, int index, String name, String price, String assetPath, bool isReturned) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.h(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.w(8)),
                child: Image.asset(
                  assetPath,
                  width: Responsive.w(42),
                  height: Responsive.w(42),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title(
                      name,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isReturned ? Colors.grey : Colors.black,
                    ),
                    CustomText.subtitle(
                      price,
                      fontSize: 12,
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.w(8)),
              GestureDetector(
                onTap: isReturned ? null : () => _showReturnDialog(context, index),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(12),
                    vertical: Responsive.h(6),
                  ),
                  decoration: BoxDecoration(
                    color: isReturned ? Colors.grey.shade100 : const Color(0xFFFFF2EC),
                    borderRadius: BorderRadius.circular(Responsive.w(16)),
                    border: Border.all(
                      color: isReturned ? Colors.grey.shade300 : AppColors.primary,
                      width: 1.0,
                    ),
                  ),
                  child: CustomText.title(
                    isReturned ? 'Returned' : 'Return',
                    color: isReturned ? Colors.grey : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(10)),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: Responsive.h(48),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              border: Border.all(
                color: AppColors.primary,
                width: Responsive.w(1.5),
              ),
            ),
            child: InkWell(
              onTap: () {
                context.read<TransactionBloc>().add(ToggleReorderScreenEvent(true));
              },
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.replay,
                      color: AppColors.primary,
                      size: Responsive.w(18),
                    ),
                    SizedBox(width: Responsive.w(6)),
                    CustomText.title(
                      'Reorder',
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.w(16)),
        Expanded(
          child: Container(
            height: Responsive.h(48),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: Responsive.w(6),
                  offset: Offset(0, Responsive.h(3)),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading invoice...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_outlined,
                      color: AppColors.black,
                      size: Responsive.w(18),
                    ),
                    SizedBox(width: Responsive.w(6)),
                    CustomText.title(
                      'Invoice',
                      color: AppColors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String val, {bool isBold = false, bool isGray = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText.title(
          label,
          fontSize: 13,
          color: isGray ? AppColors.grayFont : AppColors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
        CustomText.title(
          val,
          fontSize: 13,
          color: isGray ? AppColors.grayFont : AppColors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
      thickness: 1,
    );
  }
}
