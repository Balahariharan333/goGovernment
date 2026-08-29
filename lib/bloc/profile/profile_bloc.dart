import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  static final ProfileBloc instance = ProfileBloc._();

  ProfileBloc._() : super(ProfileState.initial()) {
    on<UpdateProfileEvent>((event, emit) {
      emit(state.copyWith(
        name: event.name,
        email: event.email,
      ));
    });

    on<UpdatePhoneEvent>((event, emit) {
      emit(state.copyWith(
        phone: event.phone,
      ));
    });
  }
}
