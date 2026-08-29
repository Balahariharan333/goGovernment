abstract class OrderTrackingEvent {}

class UpdateTrackingStepEvent extends OrderTrackingEvent {
  final int step;
  UpdateTrackingStepEvent(this.step);
}
