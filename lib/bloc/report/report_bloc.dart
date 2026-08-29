import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportState.initial()) {
    on<ToggleActivityTypeEvent>((event, emit) {
      emit(state.copyWith(isMyActivity: event.isMyActivity));
    });

    on<ChangeReportFilterEvent>((event, emit) {
      emit(state.copyWith(selectedFilter: event.filter));
    });
  }
}
