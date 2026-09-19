import 'package:equatable/equatable.dart';

abstract class RiderAuthEvent extends Equatable {
  const RiderAuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckRiderAuthSessionEvent extends RiderAuthEvent {}

class SendRiderOtpEvent extends RiderAuthEvent {
  final String phone;
  const SendRiderOtpEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyRiderOtpEvent extends RiderAuthEvent {
  final String phone;
  final String otp;
  const VerifyRiderOtpEvent({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class SaveRiderProfileEvent extends RiderAuthEvent {
  final String name;
  final String vehicleType;
  final String vehicleNumber;

  const SaveRiderProfileEvent({
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
  });

  @override
  List<Object?> get props => [name, vehicleType, vehicleNumber];
}

class RiderLogoutEvent extends RiderAuthEvent {}
