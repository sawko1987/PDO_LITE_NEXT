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
    this.machineId = '',
    this.versionId = '',
    this.structureOccurrenceId = '',
    this.structureDisplayName = '',
    this.operationName = '',
    this.workshop = '',
    this.reportedQuantity = 0,
    this.remainingQuantity = 0,
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

  factory TaskSummaryDto.fromJson(Map<String, Object?> json) {
    return TaskSummaryDto(
      id: json['id'] as String? ?? '',
      planItemId: json['planItemId'] as String? ?? '',
      operationOccurrenceId: json['operationOccurrenceId'] as String? ?? '',
      requiredQuantity: (json['requiredQuantity'] as num?)?.toDouble() ?? 0,
      assigneeId: json['assigneeId'] as String?,
      status: json['status'] as String? ?? '',
      isClosed: json['isClosed'] as bool? ?? false,
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      structureDisplayName: json['structureDisplayName'] as String? ?? '',
      operationName: json['operationName'] as String? ?? '',
      workshop: json['workshop'] as String? ?? '',
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String planItemId;
  final String operationOccurrenceId;
  final double requiredQuantity;
  final String? assigneeId;
  final String status;
  final bool isClosed;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String structureDisplayName;
  final String operationName;
  final String workshop;
  final double reportedQuantity;
  final double remainingQuantity;

  Map<String, Object?> toJson() => {
    'id': id,
    'planItemId': planItemId,
    'operationOccurrenceId': operationOccurrenceId,
    'requiredQuantity': requiredQuantity,
    'assigneeId': assigneeId,
    'status': status,
    'isClosed': isClosed,
    'machineId': machineId,
    'versionId': versionId,
    'structureOccurrenceId': structureOccurrenceId,
    'structureDisplayName': structureDisplayName,
    'operationName': operationName,
    'workshop': workshop,
    'reportedQuantity': reportedQuantity,
    'remainingQuantity': remainingQuantity,
  };
}
