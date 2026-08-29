class ProfileState {
  final String name;
  final String email;
  final String phone;

  ProfileState({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ProfileState.initial() {
    return ProfileState(
      name: 'SURIYAPRAKASH',
      email: 'suryaprakash@gmail.com',
      phone: '+91 12345 09876',
    );
  }

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
