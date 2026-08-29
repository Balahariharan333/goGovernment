abstract class RiderChatEvent {}

class SendChatMessageEvent extends RiderChatEvent {
  final String text;
  SendChatMessageEvent(this.text);
}

class ClearChatEvent extends RiderChatEvent {}
