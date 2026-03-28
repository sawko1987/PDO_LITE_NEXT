import 'wip_entry_status.dart';

class WipEntry {
  const WipEntry({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.operationOccurrenceId,
    required this.balanceQuantity,
    this.status = WipEntryStatus.open,
  });

  final String id;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String operationOccurrenceId;
  final double balanceQuantity;
  final WipEntryStatus status;

  bool get blocksCompletion =>
      status == WipEntryStatus.open && balanceQuantity > 0;
}
