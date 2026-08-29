abstract class ReportEvent {}

class ToggleActivityTypeEvent extends ReportEvent {
  final bool isMyActivity;
  ToggleActivityTypeEvent(this.isMyActivity);
}

class ChangeReportFilterEvent extends ReportEvent {
  final String filter;
  ChangeReportFilterEvent(this.filter);
}
