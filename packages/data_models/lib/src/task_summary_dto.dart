import 'package:domain/domain.dart';

class TaskSummaryDto {
  const TaskSummaryDto({
    required this.id,
    required this.planItemId,
    required this.operationOccurrenceId,
    required this.requiredQuantity,
    required this.status,
    required this.isClosed,
    this.assigneeId,
  });

  factory TaskSummaryDto.fromDomain(ProductionTask task) {
    return TaskSummaryDto(
      id: task.id,
      planItemId: task.planItemId,
      operationOccurrenceId: task.operationOccurrenceId,
      requiredQuantity: task.requiredQuantity,
      assigneeId: task.assigneeId,
      status: task.status.name,
      isClosed: task.isClosed,
    );
  }

  final String id;
  final String planItemId;
  final String operationOccurrenceId;
  final double requiredQuantity;
  final String? assigneeId;
  final String status;
  final bool isClosed;

  Map<String, Object?> toJson() => {
    'id': id,
    'planItemId': planItemId,
    'operationOccurrenceId': operationOccurrenceId,
    'requiredQuantity': requiredQuantity,
    'assigneeId': assigneeId,
    'status': status,
    'isClosed': isClosed,
  };
}
