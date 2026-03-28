class ExecutionReport {
  const ExecutionReport({
    required this.id,
    required this.taskId,
    required this.reportedBy,
    required this.reportedAt,
    required this.reportedQuantity,
    this.reason,
    this.acceptedAt,
  });

  final String id;
  final String taskId;
  final String reportedBy;
  final DateTime reportedAt;
  final double reportedQuantity;
  final String? reason;
  final DateTime? acceptedAt;

  bool get isAccepted => acceptedAt != null;
}
