import 'execution_report_outcome.dart';

class ExecutionReport {
  const ExecutionReport({
    required this.id,
    required this.taskId,
    required this.reportedBy,
    required this.reportedAt,
    required this.reportedQuantity,
    required this.outcome,
    this.reason,
    this.acceptedAt,
  });

  final String id;
  final String taskId;
  final String reportedBy;
  final DateTime reportedAt;
  final double reportedQuantity;
  final ExecutionReportOutcome outcome;
  final String? reason;
  final DateTime? acceptedAt;

  bool get isAccepted => acceptedAt != null;
}
