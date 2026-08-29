abstract class TransactionEvent {}

class ToggleReorderScreenEvent extends TransactionEvent {
  final bool showReorderScreen;
  ToggleReorderScreenEvent(this.showReorderScreen);
}

class ReturnWatermelonProductEvent extends TransactionEvent {
  final int index;
  ReturnWatermelonProductEvent(this.index);
}
