abstract class ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String email;
  UpdateProfileEvent(this.name, this.email);
}

class UpdatePhoneEvent extends ProfileEvent {
  final String phone;
  UpdatePhoneEvent(this.phone);
}
