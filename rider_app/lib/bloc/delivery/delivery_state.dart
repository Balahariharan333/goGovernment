import 'package:equatable/equatable.dart';
import '../../model/delivery_order_model.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryLoaded extends DeliveryState {
  final bool isOnline;
  final List<DeliveryOrder> availableOrders;
  final List<DeliveryOrder> activeOrders;
  final List<DeliveryOrder> completedOrders;
  final double totalEarnings;
  final int completedCount;

  const DeliveryLoaded({
    required this.isOnline,
    required this.availableOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.totalEarnings,
    required this.completedCount,
  });

  DeliveryLoaded copyWith({
    bool? isOnline,
    List<DeliveryOrder>? availableOrders,
    List<DeliveryOrder>? activeOrders,
    List<DeliveryOrder>? completedOrders,
    double? totalEarnings,
    int? completedCount,
  }) {
    return DeliveryLoaded(
      isOnline: isOnline ?? this.isOnline,
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrders: activeOrders ?? this.activeOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  List<Object?> get props => [
        isOnline,
        availableOrders,
        activeOrders,
        completedOrders,
        totalEarnings,
        completedCount,
      ];
}

class DeliveryError extends DeliveryState {
  final String message;
  const DeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}
