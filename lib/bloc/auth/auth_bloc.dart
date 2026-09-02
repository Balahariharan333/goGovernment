import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(HiveService.isLoggedIn ? AuthSuccess() : AuthInitial()) {
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.setUserPhone(event.phone);
      // Simulate API call for sending OTP
      await Future.delayed(const Duration(milliseconds: 800));
      emit(OtpSent(event.phone));
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      // Simulate API call for verification
      await Future.delayed(const Duration(milliseconds: 1000));
      if (event.otp.length == 4) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure('Invalid OTP code. Please try again.'));
      }
    });

    on<LogoutEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.clearAuth();
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthInitial());
    });
  }
}
