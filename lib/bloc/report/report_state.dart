class ReportState {
  final bool isMyActivity;
  final String selectedFilter;

  ReportState({
    required this.isMyActivity,
    required this.selectedFilter,
  });

  factory ReportState.initial() {
    return ReportState(
      isMyActivity: true,
      selectedFilter: 'All',
    );
  }

  ReportState copyWith({
    bool? isMyActivity,
    String? selectedFilter,
  }) {
    return ReportState(
      isMyActivity: isMyActivity ?? this.isMyActivity,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}
