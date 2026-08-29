import 'package:flutter_bloc/flutter_bloc.dart';
import 'complaint_event.dart';
import 'complaint_state.dart';

class ComplaintBloc extends Bloc<ComplaintEvent, ComplaintState> {
  ComplaintBloc() : super(ComplaintState.initial()) {
    on<SelectComplaintCategoryEvent>((event, emit) {
      emit(state.copyWith(selectedCategory: event.category));
    });

    on<PickComplaintImageEvent>((event, emit) {
      emit(state.copyWith(imageFile: event.image));
    });

    on<SubmitComplaintEvent>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      await Future.delayed(const Duration(milliseconds: 1500));
      emit(state.copyWith(isSubmitting: false, isSubmitted: true));
    });

    on<ClearComplaintEvent>((event, emit) {
      emit(ComplaintState.initial());
    });
  }
}
