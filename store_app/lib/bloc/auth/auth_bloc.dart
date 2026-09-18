import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import '../../network/auth_api_service.dart';
import '../../services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static final AuthBloc instance = AuthBloc._internal();

  factory AuthBloc() => instance;

  AuthBloc._internal() : super(HiveService.isLoggedIn ? AuthSuccessState(
    userId: HiveService.userId,
    phone: HiveService.userPhone,
  ) : AuthInitial()) {

    on<CheckAuthSessionEvent>((event, emit) {
      if (HiveService.isLoggedIn) {
        emit(AuthSuccessState(
          userId: HiveService.userId,
          phone: HiveService.userPhone,
        ));
      } else {
        emit(AuthInitial());
      }
    });

    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.setUserPhone(event.phone);

      final res = await AuthApiService.sendOtp(event.phone);

      if (res != null && res['success'] == true) {
        final otp = res['otp']?.toString();
        if (otp != null && otp.isNotEmpty) {
          await NotificationService.showOtpNotification(otp: otp);
        }
        emit(OtpSentState(phone: event.phone, otp: otp));
      } else {
        emit(AuthFailureState(res?['error'] ?? res?['message'] ?? 'Failed to send OTP'));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());

      final res = await AuthApiService.verifyOtp(event.phone, event.otp);

      if (res != null && res['success'] == true) {
        final userId = res['userId']?.toString() ?? res['user']?['userId']?.toString() ?? '';
        final isNewUser = res['isNewUser'] == true;

        await HiveService.setLoggedIn(true);
        await HiveService.setUserPhone(event.phone);
        await HiveService.setUserId(userId);
        await HiveService.setUserRole('store_owner');

        if (res['user'] != null && res['user']['userName'] != null) {
          await HiveService.setUserName(res['user']['userName'].toString());
        }

        emit(AuthSuccessState(
          userId: userId,
          phone: event.phone,
          isNewUser: isNewUser,
          userData: res['user'] as Map<String, dynamic>?,
        ));
      } else {
        emit(AuthFailureState(res?['error'] ?? 'Invalid OTP code'));
      }
    });

    on<LogoutEvent>((event, emit) async {
      emit(AuthLoading());
      await HiveService.clearAuth();
      emit(AuthInitial());
    });
  }
}
