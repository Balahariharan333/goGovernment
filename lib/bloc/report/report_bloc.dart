import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../../service/firebase_service.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportState.initial()) {
    on<LoadReportsEvent>((event, emit) async {
      await emit.forEach(
        FirebaseService.streamAllComplaints(),
        onData: (List<Map<String, dynamic>> allComplaints) {
          final myId = HiveService.citizenId;
          final myReports = allComplaints.where((c) => c['citizenId'] == myId).toList();
          final otherReports = allComplaints.where((c) => c['citizenId'] != myId).toList();
          
          return state.copyWith(
            myReports: myReports,
            otherReports: otherReports,
          );
        },
        onError: (error, stackTrace) {
          debugPrint('[ReportBloc] Error listening to complaints: $error');
          // Fallback to local
          final stored = HiveService.getMyComplaints();
          return state.copyWith(myReports: stored);
        },
      );
    });

    on<ClearAllComplaintsEvent>((event, emit) async {
      await HiveService.clearComplaints();
      emit(state.copyWith(myReports: []));
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

    on<ToggleLikeReportEvent>((event, emit) async {
      // Find the complaint to see if it's currently liked by us
      final myId = HiveService.citizenId;
      final allReports = [...state.myReports, ...state.otherReports];
      final target = allReports.firstWhere((r) => r['id'] == event.reportId, orElse: () => {});
      
      if (target.isNotEmpty) {
        final likedBy = List<String>.from(target['likedBy'] ?? []);
        final isCurrentlyLiked = likedBy.contains(myId);
        await FirebaseService.toggleLike(event.reportId, isCurrentlyLiked);
      }
    });

    on<AddCommentToReportEvent>((event, emit) async {
      await FirebaseService.addComment(event.reportId, event.comment, event.userName);
    });
  }
}
