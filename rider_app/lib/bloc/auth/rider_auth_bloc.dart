import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import '../../network/rider_api_service.dart';
import '../../services/notification_service.dart';
import 'rider_auth_event.dart';
import 'rider_auth_state.dart';

class RiderAuthBloc extends Bloc<RiderAuthEvent, RiderAuthState> {
  static final RiderAuthBloc instance = RiderAuthBloc._internal();

  factory RiderAuthBloc() => instance;

  RiderAuthBloc._internal()
      : super(
          HiveService.isLoggedIn
              ? RiderAuthSuccessState(
                  userId: HiveService.userId,
                  name: HiveService.userName,
                  phone: HiveService.userPhone,
                  vehicleType: HiveService.vehicleType,
                  vehicleNumber: HiveService.vehicleNumber,
                )
              : RiderAuthInitial(),
        ) {
    on<CheckRiderAuthSessionEvent>((event, emit) {
      if (HiveService.isLoggedIn) {
        emit(RiderAuthSuccessState(
          userId: HiveService.userId,
          name: HiveService.userName,
          phone: HiveService.userPhone,
          vehicleType: HiveService.vehicleType,
          vehicleNumber: HiveService.vehicleNumber,
        ));
      } else {
        emit(RiderAuthInitial());
      }
    });

    on<SendRiderOtpEvent>((event, emit) async {
      emit(RiderAuthLoading());
      await HiveService.setUserPhone(event.phone);

      final res = await RiderApiService.sendOtp(event.phone);

      if (res['success'] == true) {
        final otp = res['otp']?.toString();
        if (otp != null && otp.isNotEmpty) {
          await NotificationService.showOtpNotification(otp: otp);
        }
        emit(RiderOtpSentState(phone: event.phone, otp: otp));
      } else {
        emit(RiderAuthFailureState(res['error'] ?? res['message'] ?? 'Failed to send OTP'));
      }
    });

    on<VerifyRiderOtpEvent>((event, emit) async {
      emit(RiderAuthLoading());

      final res = await RiderApiService.verifyOtp(event.phone, event.otp);

      if (res['success'] == true) {
        final userId = res['userId']?.toString() ?? res['user']?['userId']?.toString() ?? '';
        final isNewUser = res['isNewUser'] == true;

        await HiveService.setLoggedIn(true);
        await HiveService.setUserPhone(event.phone);
        await HiveService.setUserId(userId);

        final userObj = res['user'];
        if (userObj != null && userObj['userName'] != null && userObj['userName'].toString().trim().isNotEmpty) {
          final name = userObj['userName'].toString();
          await HiveService.setUserName(name);

          emit(RiderAuthSuccessState(
            userId: userId,
            name: name,
            phone: event.phone,
            vehicleType: HiveService.vehicleType,
            vehicleNumber: HiveService.vehicleNumber,
          ));
        } else if (isNewUser || HiveService.userName.isEmpty) {
          emit(RiderProfilePendingState(userId: userId, phone: event.phone));
        } else {
          emit(RiderAuthSuccessState(
            userId: userId,
            name: HiveService.userName,
            phone: event.phone,
            vehicleType: HiveService.vehicleType,
            vehicleNumber: HiveService.vehicleNumber,
          ));
        }
      } else {
        emit(RiderAuthFailureState(res['error'] ?? 'Invalid verification code'));
      }
    });

    on<SaveRiderProfileEvent>((event, emit) async {
      emit(RiderAuthLoading());

      final userId = HiveService.userId;
      await HiveService.setUserName(event.name);
      await HiveService.setVehicleType(event.vehicleType);
      await HiveService.setVehicleNumber(event.vehicleNumber);

      await RiderApiService.updateProfile(
        userId: userId,
        userName: event.name,
      );

      emit(RiderAuthSuccessState(
        userId: userId,
        name: event.name,
        phone: HiveService.userPhone,
        vehicleType: event.vehicleType,
        vehicleNumber: event.vehicleNumber,
      ));
    });

    on<RiderLogoutEvent>((event, emit) async {
      await HiveService.clearAuth();
      emit(RiderAuthInitial());
    });
  }
}
