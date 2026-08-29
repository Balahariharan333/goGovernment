import 'package:flutter_bloc/flutter_bloc.dart';
import 'direction_event.dart';
import 'direction_state.dart';

class DirectionBloc extends Bloc<DirectionEvent, DirectionState> {
  DirectionBloc() : super(DirectionInitial()) {
    on<FetchDirections>((event, emit) async {
      emit(DirectionLoading());
      // Simulate fetching directions; replace with real service.
      await Future.delayed(const Duration(milliseconds: 300));
      // Mock polyline data or route info.
      final mockData = {'route': 'mock_polyline'};
      emit(DirectionLoaded(data: mockData));
    });
  }
}
