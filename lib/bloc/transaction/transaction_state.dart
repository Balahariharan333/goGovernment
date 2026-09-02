import '../../hive/hive_service.dart';

class TransactionState {
  final List<Map<String, dynamic>> transactions;
  final double walletBalance;
  final int coinsBalance;
  final bool showReorderScreen;
  final List<bool> watermelonReturned;

  TransactionState({
    required this.transactions,
    required this.walletBalance,
    required this.coinsBalance,
    required this.showReorderScreen,
    required this.watermelonReturned,
  });

  static final List<Map<String, dynamic>> defaultTransactions = [
    {
      'id': 'ORD-20261112-9876',
      'title': 'Sanjivani Medicals',
      'subtitle': 'Sent by you · Nov 12 - 10:22 pm',
      'amount': '-200',
      'isPositive': false,
      'status': 'Delivered',
      'date': 'Nov 12 - 10:22 pm',
      'items': [
        {'title': 'Paracetamol 500mg', 'price': '₹99.0', 'qty': 1, 'image': 'assets/images/product1.png'},
        {'title': 'Vitamin C Tablets', 'price': '₹101.0', 'qty': 1, 'image': 'assets/images/product1.png'},
      ],
      'address': '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru',
      'listingPrice': '₹250.00',
      'sellingPrice': '₹200.00',
      'grandTotal': '₹200.00',
      'paid': '₹200.00',
    },
    {
      'id': 'ORD-20261113-1122',
      'title': 'Complaint coins',
      'subtitle': 'Earned through activity · Nov 13 - 09:30 am',
      'amount': '+200',
      'isPositive': true,
      'status': 'Credited',
      'date': 'Nov 13 - 09:30 am',
      'items': [],
      'address': 'Government Portal Reward',
      'listingPrice': '₹0.00',
      'sellingPrice': '₹200.00',
      'grandTotal': '₹200.00',
      'paid': '₹200.00',
    },
    {
      'id': 'ORD-20261113-5432',
      'title': 'HealthPlus Pharmacy',
      'subtitle': 'Received from you · Nov 13 - 08:15 am',
      'amount': '-150',
      'isPositive': false,
      'status': 'Delivered',
      'date': 'Nov 13 - 08:15 am',
      'items': [
        {'title': 'First Aid Bandages', 'price': '₹150.0', 'qty': 1, 'image': 'assets/images/product2.png'},
      ],
      'address': '552, 2nd Floor 16th Main, 15th Cross Rd, Bengaluru',
      'listingPrice': '₹180.00',
      'sellingPrice': '₹150.00',
      'grandTotal': '₹150.00',
      'paid': '₹150.00',
    },
    {
      'id': 'ORD-20261113-7788',
      'title': 'Wellness Rewards',
      'subtitle': 'Earned through activity · Nov 13 - 09:30 am',
      'amount': '+100',
      'isPositive': true,
      'status': 'Credited',
      'date': 'Nov 13 - 09:30 am',
      'items': [],
      'address': 'Citizen Participation Bonus',
      'listingPrice': '₹0.00',
      'sellingPrice': '₹100.00',
      'grandTotal': '₹100.00',
      'paid': '₹100.00',
    },
  ];

  factory TransactionState.initial() {
    final saved = HiveService.getMyTransactions();
    final List<Map<String, dynamic>> combined = saved.isNotEmpty
        ? saved
        : defaultTransactions;
    final wallet = HiveService.getWalletBalance();
    final coins = HiveService.getCoinsBalance();

    return TransactionState(
      transactions: combined,
      walletBalance: wallet,
      coinsBalance: coins,
      showReorderScreen: false,
      watermelonReturned: List.generate(4, (_) => false),
    );
  }

  TransactionState copyWith({
    List<Map<String, dynamic>>? transactions,
    double? walletBalance,
    int? coinsBalance,
    bool? showReorderScreen,
    List<bool>? watermelonReturned,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      walletBalance: walletBalance ?? this.walletBalance,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      showReorderScreen: showReorderScreen ?? this.showReorderScreen,
      watermelonReturned: watermelonReturned ?? this.watermelonReturned,
    );
  }
}
