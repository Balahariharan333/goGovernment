import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import '../../model/delivery_order_model.dart';
import '../../network/rider_api_service.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  static final DeliveryBloc instance = DeliveryBloc._internal();

  factory DeliveryBloc() => instance;

  DeliveryBloc._internal() : super(DeliveryInitial()) {
    on<LoadDeliveriesEvent>(_onLoadDeliveries);
    on<ToggleDutyEvent>(_onToggleDuty);
    on<AcceptDeliveryOrderEvent>(_onAcceptOrder);
    on<ConfirmStorePickupEvent>(_onConfirmStorePickup);
    on<ConfirmDeliveredEvent>(_onConfirmDelivered);
  }

  Future<void> _onLoadDeliveries(
    LoadDeliveriesEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    final currentOnline = HiveService.isOnline;
    final totalEarnings = HiveService.totalEarnings;
    final completedCount = HiveService.completedCount;
    final riderId = HiveService.userId;

    // Fetch available orders from backend ONLY if rider is online
    final List<DeliveryOrder> availableOrders;
    if (currentOnline) {
      final rawAvailable = await RiderApiService.fetchAvailableOrders();
      availableOrders = rawAvailable.where((o) => o.status == 'ready_for_pickup').toList();
    } else {
      availableOrders = [];
    }

    // Fetch rider assigned orders
    final riderOrders = await RiderApiService.fetchRiderOrders(riderId);

    final active = riderOrders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
    final completed = riderOrders.where((o) => o.status == 'delivered').toList();

    emit(DeliveryLoaded(
      isOnline: currentOnline,
      availableOrders: availableOrders,
      activeOrders: active,
      completedOrders: completed,
      totalEarnings: totalEarnings,
      completedCount: completedCount,
    ));
  }

  Future<void> _onToggleDuty(
    ToggleDutyEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    await HiveService.setIsOnline(event.isOnline);
    if (state is DeliveryLoaded) {
      emit((state as DeliveryLoaded).copyWith(isOnline: event.isOnline));
    } else {
      add(LoadDeliveriesEvent());
    }
  }

  Future<void> _onAcceptOrder(
    AcceptDeliveryOrderEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    final riderId = HiveService.userId;
    final riderName = HiveService.userName.isNotEmpty ? HiveService.userName : 'Express Rider';
    final riderPhone = HiveService.userPhone;
    final vehicleNumber = HiveService.vehicleNumber.isNotEmpty ? HiveService.vehicleNumber : 'KA-01-EE-4521';

    final res = await RiderApiService.acceptOrder(
      orderId: event.order.orderId,
      riderId: riderId,
      riderName: riderName,
      riderPhone: riderPhone,
      vehicleNumber: vehicleNumber,
    );

    if (res['success'] == true) {
      add(LoadDeliveriesEvent());
    }
  }

  Future<void> _onConfirmStorePickup(
    ConfirmStorePickupEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    final success = await RiderApiService.updateOrderStatus(
      orderId: event.orderId,
      status: 'out_for_delivery',
      note: 'Rider picked up order from store',
    );

    if (success) {
      add(LoadDeliveriesEvent());
    }
  }

  Future<void> _onConfirmDelivered(
    ConfirmDeliveredEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    final success = await RiderApiService.updateOrderStatus(
      orderId: event.orderId,
      status: 'delivered',
      note: 'Delivered successfully to customer by rider',
    );

    if (success) {
      await HiveService.addEarnings(45.0);
      await HiveService.incrementCompletedCount();
      add(LoadDeliveriesEvent());
    }
  }
}
