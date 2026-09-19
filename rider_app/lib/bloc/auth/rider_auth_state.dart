import 'package:equatable/equatable.dart';

abstract class RiderAuthState extends Equatable {
  const RiderAuthState();

  @override
  List<Object?> get props => [];
}

class RiderAuthInitial extends RiderAuthState {}

class RiderAuthLoading extends RiderAuthState {}

class RiderOtpSentState extends RiderAuthState {
  final String phone;
  final String? otp;

  const RiderOtpSentState({required this.phone, this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class RiderProfilePendingState extends RiderAuthState {
  final String userId;
  final String phone;

  const RiderProfilePendingState({required this.userId, required this.phone});

  @override
  List<Object?> get props => [userId, phone];
}

class RiderAuthSuccessState extends RiderAuthState {
  final String userId;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;

  const RiderAuthSuccessState({
    required this.userId,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
  });

  @override
  List<Object?> get props => [userId, name, phone, vehicleType, vehicleNumber];
}

class RiderAuthFailureState extends RiderAuthState {
  final String error;

  const RiderAuthFailureState(this.error);

  @override
  List<Object?> get props => [error];
}
