import 'package:flutter_bloc/flutter_bloc.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionState.initial()) {
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
  }
}
