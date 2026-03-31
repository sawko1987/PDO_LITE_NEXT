import 'execution_report_outcome.dart';
import 'wip_entry_status.dart';

class WipEntry {
  const WipEntry({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.operationOccurrenceId,
    required this.balanceQuantity,
    this.taskId,
    this.sourceReportId,
    this.sourceOutcome,
    this.status = WipEntryStatus.open,
  });

  final String id;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String operationOccurrenceId;
  final double balanceQuantity;
  final String? taskId;
  final String? sourceReportId;
  final ExecutionReportOutcome? sourceOutcome;
  final WipEntryStatus status;

  bool get blocksCompletion =>
      status == WipEntryStatus.open && balanceQuantity > 0;
}
