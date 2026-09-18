import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentState extends AuthState {
  final String phone;
  final String? otp;
  const OtpSentState({required this.phone, this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class AuthSuccessState extends AuthState {
  final String userId;
  final String phone;
  final bool isNewUser;
  final Map<String, dynamic>? userData;

  const AuthSuccessState({
    required this.userId,
    required this.phone,
    this.isNewUser = false,
    this.userData,
  });

  @override
  List<Object?> get props => [userId, phone, isNewUser, userData];
}

class AuthFailureState extends AuthState {
  final String error;
  const AuthFailureState(this.error);

  @override
  List<Object?> get props => [error];
}
