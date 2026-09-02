import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
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
      await Future.delayed(const Duration(milliseconds: 1000));

      final now = DateTime.now();
      final timeStr =
          "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      final newComplaint = {
        'id': 'CMP${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'userName': HiveService.userName.isNotEmpty ? HiveService.userName : 'user',
        'userAddress': event.location ??
            'no address found',
        'category': event.category.isNotEmpty ? event.category : 'Road Damage',
        'description': event.description,
        'status': 'Under Review',
        'statusColor': 0xFFFF5252,
        'imagePath': event.imagePath ?? state.imageFile?.path,
        'date': 'Today, $timeStr',
        'likesCount': 0,
        'isLiked': false,
        'comments': <Map<String, dynamic>>[],
      };
      await HiveService.saveComplaint(newComplaint);

      emit(state.copyWith(isSubmitting: false, isSubmitted: true));
    });

    on<ClearComplaintEvent>((event, emit) {
      emit(ComplaintState.initial());
    });
  }
}
