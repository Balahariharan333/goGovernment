class OrderTrackingState {
  final int currentStep;

  OrderTrackingState({
    required this.currentStep,
  });

  factory OrderTrackingState.initial() {
    return OrderTrackingState(
      currentStep: 0,
    );
  }

  OrderTrackingState copyWith({
    int? currentStep,
  }) {
    return OrderTrackingState(
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
