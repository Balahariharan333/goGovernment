import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  static final ProfileBloc instance = ProfileBloc._();

  ProfileBloc._() : super(ProfileState.initial()) {
    on<UpdateProfileEvent>((event, emit) {
      HiveService.saveProfile(
        name: event.name,
        email: event.email,
        imagePath: event.imagePath,
      );
      emit(state.copyWith(
        name: event.name,
        email: event.email,
        imagePath: event.imagePath ?? state.imagePath,
      ));
    });

    on<UpdatePhoneEvent>((event, emit) {
      HiveService.setUserPhone(event.phone);
      emit(state.copyWith(
        phone: event.phone,
      ));
    });

    on<UpdateProfileImageEvent>((event, emit) {
      HiveService.setUserProfileImage(event.imagePath);
      emit(state.copyWith(
        imagePath: event.imagePath,
      ));
    });
  }
}
