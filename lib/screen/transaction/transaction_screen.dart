import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';
import 'all_transactions_screen.dart';
import 'transaction_details_screen.dart';
import 'qr_scan_pay_screen.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  void _showAddMoneyBottomSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedMethod = 'UPI (GPay / PhonePe)';
    final quickAmounts = [100, 500, 1000, 2000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: Responsive.w(20),
                right: Responsive.w(20),
                top: Responsive.h(24),
                bottom: MediaQuery.of(context).viewInsets.bottom + Responsive.h(24),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.w(28))),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: Responsive.w(40),
                        height: Responsive.h(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(Responsive.w(2)),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText.header(
                          'Add Money to Wallet',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Amount input field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: Responsive.w(16), right: Responsive.w(8)),
                          child: Center(
                            widthFactor: 0.0,
                            child: CustomText.header('₹', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        hintText: 'Enter amount (e.g. 500)',
                        filled: true,
                        fillColor: const Color(0xFFFFF2EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Responsive.w(16)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(14)),

                    // Quick select chips
                    Wrap(
                      spacing: Responsive.w(8),
                      children: quickAmounts.map((amt) {
                        return ActionChip(
                          backgroundColor: const Color(0xFFFFF7F2),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          label: CustomText.title('+₹$amt', fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                          onPressed: () {
                            setModalState(() {
                              amountController.text = amt.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Responsive.h(20)),

                    CustomText.title('Select Payment Method', fontSize: 14, fontWeight: FontWeight.bold),
                    SizedBox(height: Responsive.h(10)),

                    // Payment Method Tiles
                    ...[
                      'UPI (GPay / PhonePe / Paytm)',
                      'Credit / Debit Card',
                      'Net Banking',
                    ].map((method) {
                      final isSelected = selectedMethod == method;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedMethod = method;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: Responsive.h(8)),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(14),
                            vertical: Responsive.h(12),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF2EC) : Colors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(14)),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.outliner,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText.title(method, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.primary : Colors.grey,
                                size: Responsive.w(20),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: Responsive.h(20)),

                    // Add Money Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(48),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(24)),
                          ),
                        ),
                        onPressed: () {
                          final double? amt = double.tryParse(amountController.text.trim());
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          context.read<TransactionBloc>().add(
                            AddWalletMoneyEvent(amt, paymentMethod: selectedMethod),
                          );

                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('₹${amt.toInt()} added to wallet successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: CustomText.title(
                          'Add Money to Wallet',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRedeemCoinsDialog(BuildContext context, int coinsBalance) {
    if (coinsBalance < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 50 coins required to redeem! Earn more by reporting issues.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final coinsController = TextEditingController(text: coinsBalance.toString());

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
              Icon(Icons.monetization_on, color: const Color(0xFFFFB300), size: Responsive.w(26)),
              SizedBox(width: Responsive.w(8)),
              CustomText.header('Redeem Coins', fontSize: 18, fontWeight: FontWeight.bold),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.subtitle(
                'Convert your earned grievance reward coins into real wallet cash balance (Min 100 coins required).',
                fontSize: 13,
                color: AppColors.grayFont,
              ),
              SizedBox(height: Responsive.h(12)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(12),
                  vertical: Responsive.h(10),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F2),
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CustomText.title(
                        'Rate: 100 Coins = ₹1',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: Responsive.w(6)),
                    CustomText.title(
                      '🪙 $coinsBalance',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
              ),
              if (coinsBalance < 100) ...[
                SizedBox(height: Responsive.h(8)),
                CustomText.subtitle(
                  '⚠️ You need at least 100 coins to redeem.',
                  fontSize: 11,
                  color: AppColors.error,
                ),
              ],
              SizedBox(height: Responsive.h(14)),
              TextField(
                controller: coinsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coins to redeem (Min 100)',
                  hintText: 'e.g. 100, 200, 500',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: CustomText.title('Cancel', color: AppColors.grayFont, fontSize: 14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
              ),
              onPressed: () {
                if (coinsBalance < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You need at least 100 coins to redeem into wallet cash!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final int? coinsToRedeem = int.tryParse(coinsController.text.trim());
                if (coinsToRedeem == null || coinsToRedeem < 100 || coinsToRedeem > coinsBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter at least 100 coins (100 coins = ₹1)!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final double cash = (coinsToRedeem / 100).floorToDouble();
                final int actualCoins = (cash * 100).toInt();

                context.read<TransactionBloc>().add(RedeemCoinsEvent(actualCoins));
                Navigator.pop(dialogCtx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redeemed $actualCoins Coins for ₹${cash.toInt()} into Wallet!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: CustomText.title('Redeem to Wallet', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  void _showInviteShareDialog(BuildContext context) {
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
              Icon(Icons.share, color: AppColors.primary, size: Responsive.w(24)),
              SizedBox(width: Responsive.w(8)),
              CustomText.header('Invite Friends', fontSize: 18, fontWeight: FontWeight.bold),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.subtitle(
                'Share your referral code with friends and family to help improve civic governance. Earn 100 coins on their first complaint or survey!',
                fontSize: 13,
                color: AppColors.grayFont,
              ),
              SizedBox(height: Responsive.h(16)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(14), vertical: Responsive.h(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText.header('GOV-CITIZEN-98', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    Icon(Icons.copy, color: AppColors.primary, size: Responsive.w(20)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: CustomText.title('Close', color: AppColors.grayFont, fontSize: 14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(12))),
              ),
              onPressed: () {
                // Award referral bonus
                final rewardTx = {
                  'id': 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  'title': 'Referral Bonus',
                  'subtitle': 'Invite link shared · Today',
                  'amount': '+100',
                  'isPositive': true,
                  'status': 'Credited',
                  'date': 'Today',
                  'items': [],
                  'address': 'Citizen Invite Program',
                  'listingPrice': '₹0.00',
                  'sellingPrice': '₹100.00',
                  'grandTotal': '₹100.00',
                  'paid': '₹100.00',
                };
                context.read<TransactionBloc>().add(AddCoinsEvent(100));
                context.read<TransactionBloc>().add(AddTransactionEvent(rewardTx));

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite shared & 100 Coins credited to your account!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: CustomText.title('Share Link (+100 Coins)', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
        final double walletBalance = state.walletBalance;
        final int coinsBalance = state.coinsBalance;
        final transactions = state.transactions;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Account Balance Card (Orange-red gradient)
              Container(
                width: double.infinity,
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF4511E).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(Responsive.w(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText.title(
                          'Account balance',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        GestureDetector(
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
                      ],
                    ),
                    SizedBox(height: Responsive.h(4)),
                    CustomText.header(
                      '₹ ${walletBalance.toStringAsFixed(walletBalance.truncateToDouble() == walletBalance ? 0 : 2)}',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Add Money Button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAddMoneyBottomSheet(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(16),
                              vertical: Responsive.h(8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.w(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: const Color(0xFFF4511E),
                                  size: Responsive.w(18),
                                ),
                                SizedBox(width: Responsive.w(6)),
                                CustomText.title(
                                  'Add Money',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF4511E),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(10)),
                        GestureDetector(
                          onTap: () => _showRedeemCoinsDialog(context, coinsBalance),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(16),
                              vertical: Responsive.h(8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(Responsive.w(20)),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.redeem,
                                  color: Colors.white,
                                  size: Responsive.w(18),
                                ),
                                SizedBox(width: Responsive.w(6)),
                                CustomText.title(
                                  'Redeem Coins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                     
                     
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(20)),

              // 2. Complaint Coins & Rewards Card
              Container(
                width: double.infinity,
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(Responsive.w(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.w(8), vertical: Responsive.h(3)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(Responsive.w(8)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.monetization_on, color: Colors.white, size: Responsive.w(14)),
                                    SizedBox(width: Responsive.w(4)),
                                    CustomText.title('$coinsBalance Coins', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(6)),
                          CustomText.title(
                            'Invite a friend & get\n100 coins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                          SizedBox(height: Responsive.h(10)),
                          GestureDetector(
                            onTap: () => _showInviteShareDialog(context),
                            child: Container(
                              height: Responsive.h(32),
                              width: Responsive.w(120),
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
                          ),
                        ],
                      ),
                    ),
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

              // 4. Dynamic Recent Transactions List
              if (transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Responsive.w(24)),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Responsive.w(20)),
                    border: Border.all(color: AppColors.outliner),
                  ),
                  child: Center(
                    child: CustomText.subtitle(
                      'No transactions yet.\nEarn coins by reporting issues or shopping!',
                      textAlign: TextAlign.center,
                      fontSize: 13,
                      color: AppColors.grayFont,
                    ),
                  ),
                )
              else
                ...transactions.take(4).map((tx) {
                  final String title = tx['title']?.toString() ?? 'Transaction';
                  final String subtitle = tx['subtitle']?.toString() ?? 'Recent';
                  final String amount = tx['amount']?.toString() ?? '₹0';
                  final bool isPositive = tx['isPositive'] as bool? ?? false;

                  return Padding(
                    padding: EdgeInsets.only(bottom: Responsive.h(12)),
                    child: _buildQuickTransactionRow(
                      context,
                      title,
                      subtitle,
                      amount,
                      isPositive,
                      transaction: tx,
                    ),
                  );
                }),
              SizedBox(height: Responsive.h(30)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickTransactionRow(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
    bool isPositive, {
    Map<String, dynamic>? transaction,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              title: title,
              transaction: transaction,
            ),
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
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: Responsive.w(42),
                    height: Responsive.w(42),
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF2EC),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    child: Center(
                      child: Icon(
                        isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPositive ? const Color(0xFF4CAF50) : AppColors.primary,
                        size: Responsive.w(20),
                      ),
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
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.h(4)),
                        CustomText.subtitle(
                          subtitle,
                          fontSize: 11,
                          color: AppColors.grayFont,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
