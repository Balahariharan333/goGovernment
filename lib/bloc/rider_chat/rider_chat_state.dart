class RiderChatState {
  final List<Map<String, dynamic>> messages;

  RiderChatState({
    required this.messages,
  });

  factory RiderChatState.initial() {
    return RiderChatState(
      messages: [
        {
          'text': "I'm on the way!",
          'time': '10:00 pm',
          'isMe': false,
        },
        {
          'text': "Come fast bro.",
          'time': '10:00 pm',
          'isMe': true,
        },
      ],
    );
  }

  RiderChatState copyWith({
    List<Map<String, dynamic>>? messages,
  }) {
    return RiderChatState(
      messages: messages ?? this.messages,
    );
  }
}
