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
          final processed = allComplaints.map((c) {
            final complaintMap = Map<String, dynamic>.from(c);
            final likedBy = List<dynamic>.from(complaintMap['likedBy'] ?? []);
            complaintMap['isLiked'] = likedBy.contains(myId) || complaintMap['isLiked'] == true;
            return complaintMap;
          }).toList();

          final myReports = processed.where((c) => c['citizenId'] == myId).toList();
          final otherReports = processed.where((c) => c['citizenId'] != myId).toList();
          
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
      final myId = HiveService.citizenId;
      final allReports = [...state.myReports, ...state.otherReports];
      final targetIndex = allReports.indexWhere((r) => r['id'] == event.reportId);
      
      if (targetIndex != -1) {
        final target = Map<String, dynamic>.from(allReports[targetIndex]);
        final likedBy = List<dynamic>.from(target['likedBy'] ?? []);
        final isCurrentlyLiked = likedBy.contains(myId) || target['isLiked'] == true;
        final currentCount = (target['likesCount'] as num?)?.toInt() ?? 0;

        final newIsLiked = !isCurrentlyLiked;
        final newLikedBy = List<dynamic>.from(likedBy);
        if (newIsLiked) {
          if (!newLikedBy.contains(myId)) newLikedBy.add(myId);
        } else {
          newLikedBy.remove(myId);
        }
        final newCount = (currentCount + (newIsLiked ? 1 : -1)).clamp(0, 999999);

        target['isLiked'] = newIsLiked;
        target['likedBy'] = newLikedBy;
        target['likesCount'] = newCount;

        final updatedMy = state.myReports.map((r) {
          return r['id'] == event.reportId ? target : r;
        }).toList();
        final updatedOther = state.otherReports.map((r) {
          return r['id'] == event.reportId ? target : r;
        }).toList();

        emit(state.copyWith(
          myReports: updatedMy,
          otherReports: updatedOther,
        ));

        await FirebaseService.toggleLike(event.reportId, isCurrentlyLiked);
      }
    });

    on<AddCommentToReportEvent>((event, emit) async {
      await FirebaseService.addComment(event.reportId, event.comment, event.userName);
    });
  }
}
