import 'package:domain/domain.dart';

class DemoContractStore {
  DemoContractStore()
    : _machines = [
        const Machine(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'PDO 100',
          activeVersionId: 'ver-2026-03',
        ),
      ],
      _versions = [
        MachineVersion(
          id: 'ver-2026-03',
          machineId: 'machine-1',
          label: 'v2026.03',
          createdAt: DateTime.utc(2026, 3, 1),
          status: MachineVersionStatus.published,
        ),
        MachineVersion(
          id: 'ver-2026-04-draft',
          machineId: 'machine-1',
          label: 'v2026.04-draft',
          createdAt: DateTime.utc(2026, 3, 20),
          status: MachineVersionStatus.draft,
        ),
      ],
      _structureOccurrences = const [
        StructureOccurrence(
          id: 'occ-1',
          versionId: 'ver-2026-03',
          catalogItemId: 'catalog-1',
          pathKey: 'machine/frame',
          displayName: 'Frame',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
        StructureOccurrence(
          id: 'occ-2',
          versionId: 'ver-2026-03',
          catalogItemId: 'catalog-2',
          pathKey: 'machine/body/panel',
          displayName: 'Body Panel',
          quantityPerMachine: 1,
          parentOccurrenceId: 'occ-1',
          workshop: 'WS-2',
        ),
        StructureOccurrence(
          id: 'occ-3',
          versionId: 'ver-2026-04-draft',
          catalogItemId: 'catalog-3',
          pathKey: 'machine/draft-kit',
          displayName: 'Draft Kit',
          quantityPerMachine: 1,
          workshop: 'WS-3',
        ),
      ],
      _operationOccurrences = const [
        OperationOccurrence(
          id: 'op-1',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-1',
          name: 'Cut',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
        OperationOccurrence(
          id: 'op-2',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-2',
          name: 'Weld',
          quantityPerMachine: 1,
          workshop: 'WS-2',
        ),
        OperationOccurrence(
          id: 'op-3',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-2',
          name: 'Paint',
          quantityPerMachine: 1,
          workshop: 'WS-2',
        ),
        OperationOccurrence(
          id: 'op-4',
          versionId: 'ver-2026-04-draft',
          structureOccurrenceId: 'occ-3',
          name: 'Draft Op',
          quantityPerMachine: 1,
          workshop: 'WS-3',
        ),
      ],
      _plans = [
        Plan(
          id: 'plan-1',
          machineId: 'machine-1',
          versionId: 'ver-2026-03',
          title: 'Shift plan 2026-03-28',
          createdAt: DateTime.utc(2026, 3, 28, 6),
          status: PlanStatus.released,
          items: const [
            PlanItem(
              id: 'plan-item-1',
              source: PlanItemSource(
                machineId: 'machine-1',
                versionId: 'ver-2026-03',
                structureOccurrenceId: 'occ-1',
                catalogItemId: 'catalog-1',
              ),
              requestedQuantity: 12,
            ),
            PlanItem(
              id: 'plan-item-2',
              source: PlanItemSource(
                machineId: 'machine-1',
                versionId: 'ver-2026-03',
                structureOccurrenceId: 'occ-2',
                catalogItemId: 'catalog-2',
              ),
              requestedQuantity: 4,
              hasRecordedExecution: true,
            ),
          ],
          revisions: [
            PlanRevision(
              id: 'plan-revision-1',
              planId: 'plan-1',
              revisionNumber: 1,
              changedBy: 'planner-1',
              changedAt: DateTime.utc(2026, 3, 28, 7, 15),
              changes: const [
                PlanFieldChange(
                  targetId: 'plan-item-1',
                  field: 'requestedQuantity',
                  beforeValue: '10',
                  afterValue: '12',
                ),
              ],
            ),
          ],
        ),
      ],
      _tasks = [
        const ProductionTask(
          id: 'task-1',
          planItemId: 'plan-item-1',
          operationOccurrenceId: 'op-1',
          requiredQuantity: 12,
          assigneeId: 'master-1',
          status: TaskStatus.inProgress,
        ),
        const ProductionTask(
          id: 'task-2',
          planItemId: 'plan-item-2',
          operationOccurrenceId: 'op-2',
          requiredQuantity: 4,
          assigneeId: 'master-2',
          status: TaskStatus.pending,
        ),
      ],
      _reportsByTask = {
        'task-1': [
          ExecutionReport(
            id: 'report-1',
            taskId: 'task-1',
            reportedBy: 'master-1',
            reportedAt: DateTime.utc(2026, 3, 28, 10, 30),
            reportedQuantity: 6,
            acceptedAt: DateTime.utc(2026, 3, 28, 10, 35),
          ),
        ],
        'task-2': const [],
      },
      _problems = const [
        Problem(
          id: 'problem-1',
          machineId: 'machine-1',
          taskId: 'task-1',
          title: 'Waiting for fixture',
          status: ProblemStatus.inProgress,
        ),
      ],
      _wipEntries = const [
        WipEntry(
          id: 'wip-1',
          machineId: 'machine-1',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-1',
          operationOccurrenceId: 'op-1',
          balanceQuantity: 2,
          status: WipEntryStatus.open,
        ),
      ],
      _auditEntries = [
        AuditEntry(
          id: 'audit-1',
          entityType: 'plan',
          entityId: 'plan-1',
          action: AuditAction.updated,
          changedBy: 'planner-1',
          changedAt: DateTime.utc(2026, 3, 28, 7, 15),
          field: 'requestedQuantity',
          beforeValue: '10',
          afterValue: '12',
        ),
      ],
      _machineSequence = 1,
      _versionSequence = 2,
      _planSequence = 1,
      _planItemSequence = 2,
      _taskSequence = 2,
      _auditSequence = 1;

  final List<Machine> _machines;
  final List<MachineVersion> _versions;
  final List<StructureOccurrence> _structureOccurrences;
  final List<OperationOccurrence> _operationOccurrences;
  final List<Plan> _plans;
  final List<ProductionTask> _tasks;
  final Map<String, List<ExecutionReport>> _reportsByTask;
  final List<Problem> _problems;
  final List<WipEntry> _wipEntries;
  final List<AuditEntry> _auditEntries;
  final Map<String, _StoredPlanCommand> _planByCreateRequestId = {};
  final Map<String, _StoredReleaseCommand> _releaseByRequestId = {};
  int _machineSequence;
  int _versionSequence;
  int _planSequence;
  int _planItemSequence;
  int _taskSequence;
  int _auditSequence;

  List<Machine> listMachines() => List.unmodifiable(_machines);

  Machine getMachine(String machineId) {
    return _machines.firstWhere(
      (machine) => machine.id == machineId,
      orElse: () => throw const DemoStoreNotFound(
        'machine_not_found',
        'Machine was not found.',
      ),
    );
  }

  bool hasMachineCode(String machineCode) {
    return _machines.any((machine) => machine.code == machineCode);
  }

  List<MachineVersion> listVersions(String machineId) {
    getMachine(machineId);
    return List.unmodifiable(
      _versions.where((version) => version.machineId == machineId),
    );
  }

  List<StructureOccurrence> listPlanningSource(
    String machineId,
    String versionId,
  ) {
    _getVersion(machineId, versionId);
    return List.unmodifiable(
      _structureOccurrences.where((item) => item.versionId == versionId),
    );
  }

  int operationCountForOccurrence(String structureOccurrenceId) {
    return _operationOccurrences
        .where((item) => item.structureOccurrenceId == structureOccurrenceId)
        .length;
  }

  List<Plan> listPlans() => List.unmodifiable(_plans);

  Plan getPlan(String planId) {
    return _plans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => throw const DemoStoreNotFound(
        'plan_not_found',
        'Plan was not found.',
      ),
    );
  }

  StructureOccurrence getStructureOccurrence(String structureOccurrenceId) {
    return _structureOccurrences.firstWhere(
      (occurrence) => occurrence.id == structureOccurrenceId,
      orElse: () => throw const DemoStoreNotFound(
        'structure_occurrence_not_found',
        'Structure occurrence was not found.',
      ),
    );
  }

  Plan createPlan(CreatePlanCommand command) {
    _validateCreatePlanCommand(command);
    final requestSignature = _buildCreatePlanSignature(command);
    final existing = _planByCreateRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'plan_request_replayed_with_different_payload',
          'Plan create requestId was already used with different payload.',
        );
      }
      return getPlan(existing.planId);
    }

    _getVersion(command.machineId, command.versionId);
    final occurrenceIds = <String>{};
    final items = <PlanItem>[];
    for (final requestedItem in command.items) {
      if (!occurrenceIds.add(requestedItem.structureOccurrenceId)) {
        throw DemoStoreValidation(
          'duplicate_structure_occurrence',
          'Each structure occurrence can only be included once in a plan.',
          details: {
            'structureOccurrenceId': requestedItem.structureOccurrenceId,
          },
        );
      }
      if (requestedItem.requestedQuantity <= 0) {
        throw DemoStoreValidation(
          'invalid_requested_quantity',
          'requestedQuantity must be greater than zero.',
          details: {
            'structureOccurrenceId': requestedItem.structureOccurrenceId,
            'requestedQuantity': requestedItem.requestedQuantity,
          },
        );
      }

      final occurrence = getStructureOccurrence(
        requestedItem.structureOccurrenceId,
      );
      if (occurrence.versionId != command.versionId) {
        throw DemoStoreValidation(
          'structure_occurrence_version_mismatch',
          'Structure occurrence does not belong to the requested machine version.',
          details: {
            'structureOccurrenceId': requestedItem.structureOccurrenceId,
            'versionId': command.versionId,
          },
        );
      }

      items.add(
        PlanItem(
          id: 'plan-item-${++_planItemSequence}',
          source: PlanItemSource(
            machineId: command.machineId,
            versionId: command.versionId,
            structureOccurrenceId: occurrence.id,
            catalogItemId: occurrence.catalogItemId,
          ),
          requestedQuantity: requestedItem.requestedQuantity,
        ),
      );
    }

    if (items.isEmpty) {
      throw const DemoStoreValidation(
        'plan_requires_items',
        'Plan must include at least one structure occurrence.',
      );
    }

    final plan = Plan(
      id: 'plan-${++_planSequence}',
      machineId: command.machineId,
      versionId: command.versionId,
      title: command.title.trim(),
      createdAt: DateTime.now().toUtc(),
      items: List.unmodifiable(items),
    );
    if (plan.hasDuplicateStructureOccurrences) {
      throw const DemoStoreValidation(
        'duplicate_structure_occurrence',
        'Each structure occurrence can only be included once in a plan.',
      );
    }

    _plans.add(plan);
    _planByCreateRequestId[command.requestId] = _StoredPlanCommand(
      signature: requestSignature,
      planId: plan.id,
    );
    return plan;
  }

  ReleasePlanResult releasePlan(ReleasePlanCommand command) {
    _validateReleasePlanCommand(command);
    final requestSignature = '${command.planId}::${command.releasedBy}';
    final existing = _releaseByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'plan_request_replayed_with_different_payload',
          'Plan release requestId was already used with different payload.',
        );
      }
      return existing.result;
    }

    final planIndex = _plans.indexWhere((plan) => plan.id == command.planId);
    if (planIndex == -1) {
      throw const DemoStoreNotFound('plan_not_found', 'Plan was not found.');
    }

    final plan = _plans[planIndex];
    if (!plan.canRelease) {
      throw DemoStoreConflict(
        'plan_release_not_allowed',
        'Only non-empty draft plans can be released.',
        details: {'planId': command.planId, 'status': plan.status.name},
      );
    }
    if (plan.hasDuplicateStructureOccurrences) {
      throw const DemoStoreValidation(
        'duplicate_structure_occurrence',
        'Each structure occurrence can only be included once in a plan.',
      );
    }

    final generatedTasks = <ProductionTask>[];
    for (final item in plan.items) {
      final operations = _operationOccurrences.where(
        (operation) =>
            operation.versionId == plan.versionId &&
            operation.structureOccurrenceId == item.structureOccurrenceId,
      );
      for (final operation in operations) {
        generatedTasks.add(
          ProductionTask(
            id: 'task-${++_taskSequence}',
            planItemId: item.id,
            operationOccurrenceId: operation.id,
            requiredQuantity: item.requestedQuantity * operation.quantityPerMachine,
          ),
        );
      }
    }

    final releasedPlan = Plan(
      id: plan.id,
      machineId: plan.machineId,
      versionId: plan.versionId,
      title: plan.title,
      createdAt: plan.createdAt,
      items: plan.items,
      status: PlanStatus.released,
      revisions: plan.revisions,
    );
    _plans[planIndex] = releasedPlan;
    _tasks.addAll(generatedTasks);
    _appendPlanAudit(
      entityId: releasedPlan.id,
      changedBy: command.releasedBy,
      field: 'status',
      beforeValue: plan.status.name,
      afterValue: releasedPlan.status.name,
    );

    final result = ReleasePlanResult(
      planId: releasedPlan.id,
      status: releasedPlan.status,
      generatedTaskCount: generatedTasks.length,
    );
    _releaseByRequestId[command.requestId] = _StoredReleaseCommand(
      signature: requestSignature,
      result: result,
    );
    return result;
  }

  List<ProductionTask> listTasks() => List.unmodifiable(_tasks);

  List<ExecutionReport> listReports(String taskId) {
    final taskExists = _tasks.any((task) => task.id == taskId);
    if (!taskExists) {
      throw const DemoStoreNotFound('task_not_found', 'Task was not found.');
    }

    return List.unmodifiable(_reportsByTask[taskId] ?? const []);
  }

  List<Problem> listProblems() => List.unmodifiable(_problems);

  List<WipEntry> listWipEntries() => List.unmodifiable(_wipEntries);

  List<AuditEntry> listAuditEntries() => List.unmodifiable(_auditEntries);

  MachineVersion addImportedMachine({
    required String machineCode,
    required String machineName,
    required String versionLabel,
    required DateTime createdAt,
  }) {
    final machineId = 'machine-${++_machineSequence}';
    final versionId = 'ver-import-${++_versionSequence}';
    _machines.add(
      Machine(
        id: machineId,
        code: machineCode,
        name: machineName,
        activeVersionId: versionId,
      ),
    );

    final version = MachineVersion(
      id: versionId,
      machineId: machineId,
      label: versionLabel,
      createdAt: createdAt,
      status: MachineVersionStatus.published,
    );
    _versions.add(version);
    return version;
  }

  MachineVersion addImportedVersion({
    required String targetMachineId,
    required String versionLabel,
    required DateTime createdAt,
  }) {
    final machineIndex = _machines.indexWhere(
      (machine) => machine.id == targetMachineId,
    );
    if (machineIndex == -1) {
      throw const DemoStoreNotFound('machine_not_found', 'Machine was not found.');
    }

    final machine = _machines[machineIndex];
    final versionId = 'ver-import-${++_versionSequence}';
    final version = MachineVersion(
      id: versionId,
      machineId: targetMachineId,
      label: versionLabel,
      createdAt: createdAt,
      status: MachineVersionStatus.published,
    );
    _versions.add(version);
    _machines[machineIndex] = Machine(
      id: machine.id,
      code: machine.code,
      name: machine.name,
      activeVersionId: versionId,
    );
    return version;
  }

  MachineVersion _getVersion(String machineId, String versionId) {
    getMachine(machineId);
    return _versions.firstWhere(
      (version) => version.id == versionId && version.machineId == machineId,
      orElse: () => throw const DemoStoreNotFound(
        'machine_version_not_found',
        'Machine version was not found.',
      ),
    );
  }

  void _validateCreatePlanCommand(CreatePlanCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.title.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, and title are required.',
      );
    }
  }

  void _validateReleasePlanCommand(ReleasePlanCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.planId.trim().isEmpty ||
        command.releasedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, planId, and releasedBy are required.',
      );
    }
  }

  String _buildCreatePlanSignature(CreatePlanCommand command) {
    final itemsSignature = command.items
        .map(
          (item) => '${item.structureOccurrenceId}:${item.requestedQuantity}',
        )
        .join('|');
    return '${command.machineId}::${command.versionId}::${command.title}::$itemsSignature';
  }

  void _appendPlanAudit({
    required String entityId,
    required String changedBy,
    required String field,
    required String beforeValue,
    required String afterValue,
  }) {
    _auditEntries.add(
      AuditEntry(
        id: 'audit-${++_auditSequence}',
        entityType: 'plan',
        entityId: entityId,
        action: AuditAction.updated,
        changedBy: changedBy,
        changedAt: DateTime.now().toUtc(),
        field: field,
        beforeValue: beforeValue,
        afterValue: afterValue,
      ),
    );
  }
}

class CreatePlanCommand {
  const CreatePlanCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.title,
    required this.items,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String title;
  final List<CreatePlanItemCommand> items;
}

class CreatePlanItemCommand {
  const CreatePlanItemCommand({
    required this.structureOccurrenceId,
    required this.requestedQuantity,
  });

  final String structureOccurrenceId;
  final double requestedQuantity;
}

class ReleasePlanCommand {
  const ReleasePlanCommand({
    required this.requestId,
    required this.planId,
    required this.releasedBy,
  });

  final String requestId;
  final String planId;
  final String releasedBy;
}

class ReleasePlanResult {
  const ReleasePlanResult({
    required this.planId,
    required this.status,
    required this.generatedTaskCount,
  });

  final String planId;
  final PlanStatus status;
  final int generatedTaskCount;
}

class DemoStoreNotFound implements Exception {
  const DemoStoreNotFound(this.code, this.message, {this.details = const {}});

  final String code;
  final String message;
  final Map<String, Object?> details;
}

class DemoStoreConflict implements Exception {
  const DemoStoreConflict(this.code, this.message, {this.details = const {}});

  final String code;
  final String message;
  final Map<String, Object?> details;
}

class DemoStoreValidation implements Exception {
  const DemoStoreValidation(this.code, this.message, {this.details = const {}});

  final String code;
  final String message;
  final Map<String, Object?> details;
}

class _StoredPlanCommand {
  const _StoredPlanCommand({required this.signature, required this.planId});

  final String signature;
  final String planId;
}

class _StoredReleaseCommand {
  const _StoredReleaseCommand({required this.signature, required this.result});

  final String signature;
  final ReleasePlanResult result;
}
