import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionState.initial()) {
    on<LoadTransactionsEvent>((event, emit) {
      final raw = HiveService.getMyTransactions();
      final clean = raw.where((tx) => !TransactionState.isMock(tx)).toList();
      if (clean.length != raw.length) {
        HiveService.saveAllTransactions(clean);
      }
      final wallet = HiveService.getWalletBalance();
      final coins = HiveService.getCoinsBalance();
      emit(state.copyWith(
        transactions: clean,
        walletBalance: wallet,
        coinsBalance: coins,
      ));
    });

    on<AddTransactionEvent>((event, emit) async {
      await HiveService.saveTransaction(event.transaction);
      final updatedList = HiveService.getMyTransactions();
      emit(state.copyWith(transactions: updatedList));
    });

    on<AddWalletMoneyEvent>((event, emit) async {
      final newBalance = state.walletBalance + event.amount;
      await HiveService.setWalletBalance(newBalance);

      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dateStr = '${months[now.month - 1]} ${now.day} - ${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'pm' : 'am'}';

      final tx = {
        'id': 'TOP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'title': 'Wallet Top-up',
        'subtitle': 'Added via ${event.paymentMethod} · $dateStr',
        'amount': '+₹${event.amount.toInt()}',
        'isPositive': true,
        'status': 'Successful',
        'date': dateStr,
        'items': [],
        'address': 'Wallet Account',
        'listingPrice': '₹0.00',
        'sellingPrice': '₹${event.amount.toInt()}',
        'grandTotal': '₹${event.amount.toInt()}',
        'paid': '₹${event.amount.toInt()}',
      };

      await HiveService.saveTransaction(tx);
      final updatedList = HiveService.getMyTransactions();

      emit(state.copyWith(
        walletBalance: newBalance,
        transactions: updatedList,
      ));
    });

    on<DeductWalletMoneyEvent>((event, emit) async {
      final newBalance = (state.walletBalance - event.amount).clamp(0.0, double.infinity);
      await HiveService.setWalletBalance(newBalance);
      emit(state.copyWith(walletBalance: newBalance));
    });

    on<AddCoinsEvent>((event, emit) async {
      final newCoins = state.coinsBalance + event.coins;
      await HiveService.setCoinsBalance(newCoins);
      emit(state.copyWith(coinsBalance: newCoins));
    });

    on<RedeemCoinsEvent>((event, emit) async {
      // Minimum 100 coins required to redeem (100 coins = ₹1)
      if (state.coinsBalance < event.coins || event.coins < 100) return;
      final double cashAmount = (event.coins / 100).floorToDouble();
      if (cashAmount <= 0) return;
      final int actualCoinsToDeduct = (cashAmount * 100).toInt();
      final newCoins = state.coinsBalance - actualCoinsToDeduct;
      final newBalance = state.walletBalance + cashAmount;

      await HiveService.setCoinsBalance(newCoins);
      await HiveService.setWalletBalance(newBalance);

      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dateStr = '${months[now.month - 1]} ${now.day} - ${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'pm' : 'am'}';

      final tx = {
        'id': 'RED-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'title': 'Coins Redeemed',
        'subtitle': '${event.coins} coins converted · $dateStr',
        'amount': '+₹${cashAmount.toInt()}',
        'isPositive': true,
        'status': 'Credited',
        'date': dateStr,
        'items': [],
        'address': 'Reward Redemption',
        'listingPrice': '₹0.00',
        'sellingPrice': '₹${cashAmount.toInt()}',
        'grandTotal': '₹${cashAmount.toInt()}',
        'paid': '₹${cashAmount.toInt()}',
      };

      await HiveService.saveTransaction(tx);
      final updatedList = HiveService.getMyTransactions();

      emit(state.copyWith(
        walletBalance: newBalance,
        coinsBalance: newCoins,
        transactions: updatedList,
      ));
    });

    on<SpendCoinsEvent>((event, emit) async {
      final newCoins = (state.coinsBalance - event.coins).clamp(0, 999999);
      await HiveService.setCoinsBalance(newCoins);
      emit(state.copyWith(coinsBalance: newCoins));
    });

    on<ToggleReorderScreenEvent>((event, emit) {
      emit(state.copyWith(showReorderScreen: event.showReorderScreen));
    });

    on<ReturnWatermelonProductEvent>((event, emit) {
      final updatedList = List<bool>.from(state.watermelonReturned);
      if (event.index >= 0 && event.index < updatedList.length) {
        updatedList[event.index] = true;
      }
      emit(state.copyWith(watermelonReturned: updatedList));
    });

    on<UpdateOrderStatusEvent>((event, emit) async {
      final currentList = HiveService.getMyTransactions();
      final index = currentList.indexWhere((t) => t['id']?.toString() == event.orderId);
      if (index != -1) {
        currentList[index]['status'] = event.status;
        await HiveService.saveAllTransactions(currentList);
        emit(state.copyWith(transactions: currentList));
      } else {
        final inMemoryList = List<Map<String, dynamic>>.from(
          state.transactions.map((t) => Map<String, dynamic>.from(t)),
        );
        final mIndex = inMemoryList.indexWhere((t) => t['id']?.toString() == event.orderId);
        if (mIndex != -1) {
          inMemoryList[mIndex]['status'] = event.status;
          await HiveService.saveAllTransactions(inMemoryList);
          emit(state.copyWith(transactions: inMemoryList));
        }
      }
    });
  }
}
