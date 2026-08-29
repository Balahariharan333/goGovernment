import 'package:flutter_bloc/flutter_bloc.dart';
import 'rider_chat_event.dart';
import 'rider_chat_state.dart';

class RiderChatBloc extends Bloc<RiderChatEvent, RiderChatState> {
  RiderChatBloc() : super(RiderChatState.initial()) {
    on<SendChatMessageEvent>((event, emit) {
      final updatedList = List<Map<String, dynamic>>.from(state.messages);
      updatedList.add({
        'text': event.text,
        'time': '10:01 pm',
        'isMe': true,
      });
      emit(state.copyWith(messages: updatedList));
    });

    on<ClearChatEvent>((event, emit) {
      emit(RiderChatState.initial());
    });
  }
}
