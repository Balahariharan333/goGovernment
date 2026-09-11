import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../network/api_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(HiveService.isLoggedIn ? AuthSuccess() : AuthInitial()) {
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.setUserPhone(event.phone);

      final result = await ApiService.sendOtp(event.phone);
      if (result != null && result['success'] == true) {
        emit(OtpSent(event.phone));
      } else {
        emit(AuthFailure(result?['message'] ?? 'Failed to send OTP. Please try again.'));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());

      final phone = event.phone.isNotEmpty ? event.phone : HiveService.userPhone;
      final result = await ApiService.verifyOtp(phone, event.otp);

      if (result != null && result['success'] == true) {
        final userId = result['userId'] ?? result['user']?['userId'];
        if (userId != null && userId.toString().isNotEmpty) {
          await HiveService.setCitizenId(userId.toString());
        }

        final user = result['user'];
        if (user != null) {
          if (user['userName'] != null && user['userName'].toString().isNotEmpty) {
            await HiveService.setUserName(user['userName'].toString());
          }
          if (user['email'] != null && user['email'].toString().isNotEmpty) {
            await HiveService.setUserEmail(user['email'].toString());
          }
          if (user['profileImage'] != null && user['profileImage'].toString().isNotEmpty) {
            await HiveService.setUserProfileImage(user['profileImage'].toString());
          }
        }

        await HiveService.setLoggedIn(true);
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(result?['message'] ?? 'Invalid OTP code. Please try again.'));
      }
    });

    on<LogoutEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.clearAuth();
      await Future.delayed(const Duration(milliseconds: 300));
      emit(AuthInitial());
    });
  }
}
