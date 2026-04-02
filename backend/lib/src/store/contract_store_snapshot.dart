import 'package:domain/domain.dart';

class ContractStoreSnapshot {
  const ContractStoreSnapshot({
    required this.catalogItems,
    required this.machines,
    required this.versions,
    required this.structureOccurrences,
    required this.operationOccurrences,
    required this.users,
    required this.plans,
    required this.tasks,
    required this.reportsByTask,
    required this.problems,
    required this.problemMessagesByProblem,
    required this.wipEntries,
    required this.auditEntries,
    required this.idempotencyRecords,
    required this.machineSequence,
    required this.versionSequence,
    required this.structureSequence,
    required this.operationSequence,
    required this.planSequence,
    required this.planItemSequence,
    required this.taskSequence,
    required this.reportSequence,
    required this.problemSequence,
    required this.problemMessageSequence,
    required this.auditSequence,
    required this.userSequence,
  });

  final List<CatalogItem> catalogItems;
  final List<Machine> machines;
  final List<MachineVersion> versions;
  final List<StructureOccurrence> structureOccurrences;
  final List<OperationOccurrence> operationOccurrences;
  final List<User> users;
  final List<Plan> plans;
  final List<ProductionTask> tasks;
  final Map<String, List<ExecutionReport>> reportsByTask;
  final List<Problem> problems;
  final Map<String, List<ProblemMessage>> problemMessagesByProblem;
  final List<WipEntry> wipEntries;
  final List<AuditEntry> auditEntries;
  final List<IdempotencyRecord> idempotencyRecords;
  final int machineSequence;
  final int versionSequence;
  final int structureSequence;
  final int operationSequence;
  final int planSequence;
  final int planItemSequence;
  final int taskSequence;
  final int reportSequence;
  final int problemSequence;
  final int problemMessageSequence;
  final int auditSequence;
  final int userSequence;
}

class IdempotencyRecord {
  const IdempotencyRecord({
    required this.requestId,
    required this.category,
    required this.signature,
    this.resourceId,
    this.secondaryResourceId,
    this.status,
    this.generatedCount,
  });

  final String requestId;
  final String category;
  final String signature;
  final String? resourceId;
  final String? secondaryResourceId;
  final String? status;
  final int? generatedCount;
}
