class TaskDetailDto {
  const TaskDetailDto({
    required this.id,
    required this.planItemId,
    required this.operationOccurrenceId,
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.structureDisplayName,
    required this.operationName,
    required this.workshop,
    required this.requiredQuantity,
    required this.reportedQuantity,
    required this.remainingQuantity,
    required this.status,
    required this.isClosed,
    this.assigneeId,
  });

  factory TaskDetailDto.fromJson(Map<String, Object?> json) {
    return TaskDetailDto(
      id: json['id'] as String? ?? '',
      planItemId: json['planItemId'] as String? ?? '',
      operationOccurrenceId: json['operationOccurrenceId'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      structureDisplayName: json['structureDisplayName'] as String? ?? '',
      operationName: json['operationName'] as String? ?? '',
      workshop: json['workshop'] as String? ?? '',
      requiredQuantity: (json['requiredQuantity'] as num?)?.toDouble() ?? 0,
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      assigneeId: json['assigneeId'] as String?,
      status: json['status'] as String? ?? '',
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  final String id;
  final String planItemId;
  final String operationOccurrenceId;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String structureDisplayName;
  final String operationName;
  final String workshop;
  final double requiredQuantity;
  final double reportedQuantity;
  final double remainingQuantity;
  final String? assigneeId;
  final String status;
  final bool isClosed;

  Map<String, Object?> toJson() => {
    'id': id,
    'planItemId': planItemId,
    'operationOccurrenceId': operationOccurrenceId,
    'machineId': machineId,
    'versionId': versionId,
    'structureOccurrenceId': structureOccurrenceId,
    'structureDisplayName': structureDisplayName,
    'operationName': operationName,
    'workshop': workshop,
    'requiredQuantity': requiredQuantity,
    'reportedQuantity': reportedQuantity,
    'remainingQuantity': remainingQuantity,
    'assigneeId': assigneeId,
    'status': status,
    'isClosed': isClosed,
  };
}
