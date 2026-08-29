class TransactionState {
  final bool showReorderScreen;
  final List<bool> watermelonReturned;

  TransactionState({
    required this.showReorderScreen,
    required this.watermelonReturned,
  });

  factory TransactionState.initial() {
    return TransactionState(
      showReorderScreen: false,
      watermelonReturned: List.generate(4, (_) => false),
    );
  }

  TransactionState copyWith({
    bool? showReorderScreen,
    List<bool>? watermelonReturned,
  }) {
    return TransactionState(
      showReorderScreen: showReorderScreen ?? this.showReorderScreen,
      watermelonReturned: watermelonReturned ?? this.watermelonReturned,
    );
  }
}
