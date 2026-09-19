import 'package:flutter_bloc/flutter_bloc.dart';
import 'rider_chat_event.dart';
import 'rider_chat_state.dart';

class RiderChatBloc extends Bloc<RiderChatEvent, RiderChatState> {
  RiderChatBloc() : super(RiderChatState.initial()) {
    on<SendChatMessageEvent>((event, emit) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'pm' : 'am';
      final timeStr = '$hour:$minute $period';

      final updatedList = List<Map<String, dynamic>>.from(state.messages);
      updatedList.add({
        'text': event.text,
        'time': timeStr,
        'isMe': true,
      });
      emit(state.copyWith(messages: updatedList));
    });

    on<ClearChatEvent>((event, emit) {
      emit(RiderChatState.initial());
    });
  }
}
