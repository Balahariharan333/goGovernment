import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String title;

  const TransactionDetailsScreen({
    super.key,
    required this.title,
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
              showReorderScreen ? 'Reorder Items' : 'Order Details',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            centerTitle: false,
          ),
          body: CommonBackground(
            child: SafeArea(
              bottom: false,
              child: showReorderScreen
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
                              'Order ID - ERTYUIOP09876',
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
                                children: [
                                  _buildItemRow(context, 0, 'Watermelon', '₹ 99.0', 'assets/images/product1.png', watermelonReturned[0]),
                                  _buildItemRow(context, 1, 'Watermelon', '₹ 99.0', 'assets/images/product1.png', watermelonReturned[1]),
                                  _buildItemRow(context, 2, 'Watermelon', '₹ 99.0', 'assets/images/product1.png', watermelonReturned[1]),
                                  _buildItemRow(context, 3, 'Watermelon', '₹ 99.0', 'assets/images/product1.png', watermelonReturned[1]),
                                ],
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
                                  _buildPriceRow('Listing price', '₹225.00', isGray: true),
                                  SizedBox(height: Responsive.h(8)),
                                  _buildPriceRow('Selling price', '₹99.50', isGray: true),
                                  SizedBox(height: Responsive.h(10)),
                                  _buildDivider(),
                                  SizedBox(height: Responsive.h(10)),
                                  _buildPriceRow('Grand total', '₹99.50'),
                                  SizedBox(height: Responsive.h(8)),
                                  _buildPriceRow('Coupon applied', '₹00.00', isGray: true),
                                  SizedBox(height: Responsive.h(8)),
                                  _buildPriceRow('Cash round off', '₹00.01', isGray: true),
                                  SizedBox(height: Responsive.h(8)),
                                  _buildPriceRow('Paid', '₹100.00', isBold: true),
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
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderView(BuildContext context) {
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
          _buildReorderCard(context, 'Watermelon striped', '₹99 x 3 qty', '3 items will be added to cart', true),
          SizedBox(height: Responsive.h(12)),
          _buildReorderCard(context, 'Fresh Apple Red', '₹150 x 1 qty', 'Item is temporarily out of stock', false),
          SizedBox(height: Responsive.h(12)),
          _buildReorderCard(context, 'Fresh Spinach bunch', '₹25 x 2 qty', '2 items will be added to cart', true),
        ],
      ),
    );
  }

  Widget _buildReorderCard(BuildContext context, String title, String qtyText, String summary, bool isAvailable) {
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
                  'assets/images/product1.png',
                  width: Responsive.w(48),
                  height: Responsive.w(48),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Column(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order added to cart!'),
                        backgroundColor: Colors.green,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Column(
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
                ],
              ),
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
