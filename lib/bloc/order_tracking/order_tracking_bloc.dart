import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_tracking_event.dart';
import 'order_tracking_state.dart';

class OrderTrackingBloc extends Bloc<OrderTrackingEvent, OrderTrackingState> {
  OrderTrackingBloc() : super(OrderTrackingState.initial()) {
    on<UpdateTrackingStepEvent>((event, emit) {
      emit(state.copyWith(currentStep: event.step));
    });
  }
}
