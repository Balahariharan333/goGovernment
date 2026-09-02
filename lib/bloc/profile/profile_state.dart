import '../../hive/hive_service.dart';

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
    final storedName = HiveService.userName;
    final storedEmail = HiveService.userEmail;
    final storedPhone = HiveService.userPhone;

    return ProfileState(
      name: storedName.isNotEmpty ? storedName : 'SURIYAPRAKASH',
      email: storedEmail.isNotEmpty ? storedEmail : 'suryaprakash@gmail.com',
      phone: storedPhone.isNotEmpty ? storedPhone : '+91 12345 09876',
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
