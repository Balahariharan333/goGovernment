import '../../hive/hive_service.dart';

class ReportState {
  final bool isMyActivity;
  final String selectedFilter;
  final List<Map<String, dynamic>> myReports;
  final List<Map<String, dynamic>> otherReports;

  ReportState({
    required this.isMyActivity,
    required this.selectedFilter,
    required this.myReports,
    required this.otherReports,
  });

  factory ReportState.initial() {
    final stored = HiveService.getMyComplaints();
    final List<Map<String, dynamic>> initialMyReports = List.from(stored);

    final otherReports = [
      {
        'userName': 'Suresh Kumar',
        'userAddress': '124, 5th Cross Rd, 1st Sector, HSR Layout, Bengaluru, Karnataka 560102',
        'id': 'lkjhgfdsa1',
        'category': 'Streetlight Outage',
        'description': 'The streetlights in this area are not working properly, making it difficult for residents to walk safely at night. Kindly inspect and resolve the issue.',
        'status': 'Under Review',
        'statusColor': 0xFFFF5252,
        'date': 'Today',
      },
      {
        'userName': 'Mahesh Hegde',
        'userAddress': '78, 19th Main Rd, 3rd Sector, HSR Layout, Bengaluru, Karnataka 560102',
        'id': 'poiuytrew2',
        'category': 'Garbage & Waste',
        'description': 'Garbage has not been cleared for the last three days. It smells terrible and is attracting stray dogs. Please resolve this immediately.',
        'status': 'In Progress',
        'statusColor': 0xFFFF9100,
        'date': 'Yesterday',
      },
      {
        'userName': 'Ganesh Prasad',
        'userAddress': '411, 24th Cross Rd, HSR Layout, Bengaluru, Karnataka 560102',
        'id': 'mnbvcxzlk3',
        'category': 'Drainage Overflow',
        'description': 'Sewer water is leaking onto the main road near the school boundary. Please send clean-up crews and fix the blockage.',
        'status': 'Resolved',
        'statusColor': 0xFF4CAF50,
        'date': '4 days ago',
      },
    ];

    return ReportState(
      isMyActivity: true,
      selectedFilter: 'All',
      myReports: initialMyReports,
      otherReports: otherReports,
    );
  }

  ReportState copyWith({
    bool? isMyActivity,
    String? selectedFilter,
    List<Map<String, dynamic>>? myReports,
    List<Map<String, dynamic>>? otherReports,
  }) {
    return ReportState(
      isMyActivity: isMyActivity ?? this.isMyActivity,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      myReports: myReports ?? this.myReports,
      otherReports: otherReports ?? this.otherReports,
    );
  }
}
