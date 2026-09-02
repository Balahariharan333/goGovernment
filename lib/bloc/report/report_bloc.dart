import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportState.initial()) {
    on<LoadReportsEvent>((event, emit) {
      final stored = HiveService.getMyComplaints();
      if (stored.isNotEmpty) {
        emit(state.copyWith(myReports: stored));
      }
    });

    on<ToggleActivityTypeEvent>((event, emit) {
      emit(state.copyWith(isMyActivity: event.isMyActivity));
    });

    on<ChangeReportFilterEvent>((event, emit) {
      emit(state.copyWith(selectedFilter: event.filter));
    });

    on<AddNewReportEvent>((event, emit) {
      final updated = List<Map<String, dynamic>>.from(state.myReports);
      updated.insert(0, event.report);
      HiveService.saveAllComplaints(updated);
      emit(state.copyWith(myReports: updated));
    });

    on<ToggleLikeReportEvent>((event, emit) {
      List<Map<String, dynamic>> updateList(List<Map<String, dynamic>> list) {
        return list.map((item) {
          if (item['id'] == event.reportId) {
            final map = Map<String, dynamic>.from(item);
            final bool wasLiked = map['isLiked'] == true;
            final int currentCount = (map['likesCount'] as num?)?.toInt() ?? 0;
            map['isLiked'] = !wasLiked;
            map['likesCount'] = !wasLiked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0);
            return map;
          }
          return item;
        }).toList();
      }

      final updatedMyReports = updateList(state.myReports);
      final updatedOtherReports = updateList(state.otherReports);

      HiveService.saveAllComplaints(updatedMyReports);

      emit(state.copyWith(
        myReports: updatedMyReports,
        otherReports: updatedOtherReports,
      ));
    });

    on<AddCommentToReportEvent>((event, emit) {
      List<Map<String, dynamic>> updateList(List<Map<String, dynamic>> list) {
        return list.map((item) {
          if (item['id'] == event.reportId) {
            final map = Map<String, dynamic>.from(item);
            final existingComments = List<dynamic>.from(map['comments'] ?? []);
            final updatedComments = List<Map<String, dynamic>>.from(
              existingComments.map((e) => Map<String, dynamic>.from(e as Map)),
            );
            updatedComments.add({
              'userName': event.userName,
              'comment': event.comment,
              'date': 'Just now',
            });
            map['comments'] = updatedComments;
            return map;
          }
          return item;
        }).toList();
      }

      final updatedMyReports = updateList(state.myReports);
      final updatedOtherReports = updateList(state.otherReports);

      HiveService.saveAllComplaints(updatedMyReports);

      emit(state.copyWith(
        myReports: updatedMyReports,
        otherReports: updatedOtherReports,
      ));
    });
  }
}
