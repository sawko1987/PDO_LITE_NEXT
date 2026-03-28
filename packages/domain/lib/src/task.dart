import 'task_status.dart';

class ProductionTask {
  const ProductionTask({
    required this.id,
    required this.planItemId,
    required this.operationOccurrenceId,
    required this.requiredQuantity,
    this.assigneeId,
    this.status = TaskStatus.pending,
  });

  final String id;
  final String planItemId;
  final String operationOccurrenceId;
  final double requiredQuantity;
  final String? assigneeId;
  final TaskStatus status;

  bool get isClosed =>
      status == TaskStatus.completed || status == TaskStatus.cancelled;
}
