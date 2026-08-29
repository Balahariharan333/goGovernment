import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import 'all_transactions_screen.dart';
import 'transaction_details_screen.dart';
import 'qr_scan_pay_screen.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Account Balance Card (Orange-red gradient)
        Container(
          width: double.infinity,
          height: Responsive.h(140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.w(24)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF8A65), // Soft orange-red
                Color(0xFFF4511E), // Deep orange-red
              ],
            ),
          ),
          padding: EdgeInsets.all(Responsive.w(20)),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText.title(
                    'Account balance',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  SizedBox(height: Responsive.h(6)),
                  CustomText.header(
                    'Rs. 54789',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QrScanPayScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: Responsive.w(38),
                    height: Responsive.w(38),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: AppColors.primary,
                      size: Responsive.w(22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(20)),

        // 2. Invite Friend Card (Coin stacks representation)
        Container(
          width: double.infinity,
          height: Responsive.h(120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.w(24)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB74D), // Light gold
                Color(0xFFE65100), // Dark orange
              ],
            ),
          ),
          padding: EdgeInsets.all(Responsive.w(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText.title(
                      'Invite a friend and get\n100 coins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                    SizedBox(height: Responsive.h(10)),
                    Container(
                      height: Responsive.h(32),
                      width: Responsive.w(110),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                      ),
                      child: Center(
                        child: CustomText.title(
                          'Share invite',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Coin image from assets
              Image.asset(
                'assets/images/coins.png',
                width: Responsive.w(90),
                height: Responsive.w(90),
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(24)),

        // 3. Transactions List Header (View All)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText.header(
              'Transactions',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllTransactionsScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(14),
                  vertical: Responsive.h(6),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                  border: Border.all(
                    color: AppColors.primary,
                    width: Responsive.w(1.2),
                  ),
                ),
                child: CustomText.title(
                  'View All',
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(16)),

        // 4. Quick list of 4 transaction cards
        _buildQuickTransactionRow(context, 'Sanjivani Medicals', 'Sent by you · Nov 12 - 10:22 pm', '-200', false),
        SizedBox(height: Responsive.h(12)),
        _buildQuickTransactionRow(context, 'Complaint coins', 'Sent by you · Nov 12 - 10:22 pm', '+200', true),
        SizedBox(height: Responsive.h(12)),
        _buildQuickTransactionRow(context, 'Sanjivani Medicals', 'Sent by you · Nov 12 - 10:22 pm', '-200', false),
        SizedBox(height: Responsive.h(12)),
        _buildQuickTransactionRow(context, 'Sanjivani Medicals', 'Sent by you · Nov 12 - 10:22 pm', '-200', false),
      ],
    );
  }


  Widget _buildQuickTransactionRow(BuildContext context, String title, String subtitle, String amount, bool isPositive) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(title: title),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.w(16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(20)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: Responsive.w(42),
                  height: Responsive.w(42),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EC),
                    borderRadius: BorderRadius.circular(Responsive.w(12)),
                  ),
                  child: Center(
                    child: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: AppColors.primary,
                      size: Responsive.w(20),
                    ),
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
                    SizedBox(height: Responsive.h(4)),
                    CustomText.subtitle(
                      subtitle,
                      fontSize: 11,
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
              ],
            ),
            CustomText.title(
              amount,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
            ),
          ],
        ),
      ),
    );
  }
}
