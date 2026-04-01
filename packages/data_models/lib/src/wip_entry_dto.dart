import 'package:domain/domain.dart';

class WipEntryDto {
  const WipEntryDto({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.operationOccurrenceId,
    required this.balanceQuantity,
    required this.status,
    required this.blocksCompletion,
    this.taskId,
    this.planId,
    this.structureDisplayName,
    this.operationName,
    this.workshop,
    this.sourceReportId,
    this.sourceOutcome,
  });

  factory WipEntryDto.fromJson(Map<String, Object?> json) {
    return WipEntryDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      operationOccurrenceId: json['operationOccurrenceId'] as String? ?? '',
      balanceQuantity: (json['balanceQuantity'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      blocksCompletion: json['blocksCompletion'] as bool? ?? false,
      taskId: json['taskId'] as String?,
      planId: json['planId'] as String?,
      structureDisplayName: json['structureDisplayName'] as String?,
      operationName: json['operationName'] as String?,
      workshop: json['workshop'] as String?,
      sourceReportId: json['sourceReportId'] as String?,
      sourceOutcome: json['sourceOutcome'] as String?,
    );
  }

  factory WipEntryDto.fromDomain(WipEntry entry) {
    return WipEntryDto(
      id: entry.id,
      machineId: entry.machineId,
      versionId: entry.versionId,
      structureOccurrenceId: entry.structureOccurrenceId,
      operationOccurrenceId: entry.operationOccurrenceId,
      balanceQuantity: entry.balanceQuantity,
      status: entry.status.name,
      blocksCompletion: entry.blocksCompletion,
      taskId: entry.taskId,
      sourceReportId: entry.sourceReportId,
      sourceOutcome: _sourceOutcomeToApi(entry.sourceOutcome),
    );
  }

  final String id;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String operationOccurrenceId;
  final double balanceQuantity;
  final String status;
  final bool blocksCompletion;
  final String? taskId;
  final String? planId;
  final String? structureDisplayName;
  final String? operationName;
  final String? workshop;
  final String? sourceReportId;
  final String? sourceOutcome;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'versionId': versionId,
    'structureOccurrenceId': structureOccurrenceId,
    'operationOccurrenceId': operationOccurrenceId,
    'balanceQuantity': balanceQuantity,
    'status': status,
    'blocksCompletion': blocksCompletion,
    'taskId': taskId,
    'planId': planId,
    'structureDisplayName': structureDisplayName,
    'operationName': operationName,
    'workshop': workshop,
    'sourceReportId': sourceReportId,
    'sourceOutcome': sourceOutcome,
  };
}

String? _sourceOutcomeToApi(ExecutionReportOutcome? outcome) {
  return switch (outcome) {
    ExecutionReportOutcome.completed => 'completed',
    ExecutionReportOutcome.partial => 'partial',
    ExecutionReportOutcome.notCompleted => 'not_completed',
    ExecutionReportOutcome.overrun => 'overrun',
    null => null,
  };
}
