import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import 'transaction_details_screen.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  final List<Map<String, dynamic>> _transactions = const [
    {
      'title': 'Sanjivani Medicals',
      'subtitle': 'Sent by you · Nov 12 - 10:22 pm',
      'amount': '-200',
      'isPositive': false,
    },
    {
      'title': 'Complaint coins',
      'subtitle': 'Earned through activity · Nov 13 - 09:30 am',
      'amount': '+200',
      'isPositive': true,
    },
    {
      'title': 'HealthPlus Pharmacy',
      'subtitle': 'Received from you · Nov 13 - 08:15 am',
      'amount': '-150',
      'isPositive': false,
    },
    {
      'title': 'Wellness Rewards',
      'subtitle': 'Earned through activity · Nov 13 - 09:30 am',
      'amount': '+100',
      'isPositive': true,
    },
    {
      'title': 'City Clinic',
      'subtitle': 'Sent by you · Nov 13 - 11:45 am',
      'amount': '-300',
      'isPositive': false,
    },
    {
      'title': 'Referral Bonus',
      'subtitle': 'Received from friend · Nov 14 - 07:00 pm',
      'amount': '+250',
      'isPositive': true,
    },
    {
      'title': 'Healthy Snacks Store',
      'subtitle': 'Sent by you · Nov 15 - 02:20 pm',
      'amount': '-120',
      'isPositive': false,
    },
    {
      'title': 'Daily Check-in Bonus',
      'subtitle': 'Earned through activity · Nov 15 - 08:00 am',
      'amount': '+50',
      'isPositive': true,
    },
  ];

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
          'Transactions',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(20),
              vertical: Responsive.h(16),
            ),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              return Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(12)),
                child: _buildTransactionCard(context, tx),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> tx) {
    final bool isPositive = tx['isPositive'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(title: tx['title']),
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
                      tx['title'],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    CustomText.subtitle(
                      tx['subtitle'],
                      fontSize: 11,
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
              ],
            ),
            CustomText.title(
              tx['amount'],
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
