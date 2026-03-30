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
  });

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

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'versionId': versionId,
    'structureOccurrenceId': structureOccurrenceId,
    'operationOccurrenceId': operationOccurrenceId,
    'balanceQuantity': balanceQuantity,
    'status': status,
    'blocksCompletion': blocksCompletion,
  };
}
