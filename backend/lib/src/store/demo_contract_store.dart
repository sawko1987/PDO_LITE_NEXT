import 'dart:math';

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
      _structureOccurrences = [
        const StructureOccurrence(
          id: 'occ-1',
          versionId: 'ver-2026-03',
          catalogItemId: 'catalog-1',
          pathKey: 'machine/frame',
          displayName: 'Frame',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
        const StructureOccurrence(
          id: 'occ-2',
          versionId: 'ver-2026-03',
          catalogItemId: 'catalog-2',
          pathKey: 'machine/body/panel',
          displayName: 'Body Panel',
          quantityPerMachine: 1,
          parentOccurrenceId: 'occ-1',
          workshop: 'WS-2',
        ),
        const StructureOccurrence(
          id: 'occ-3',
          versionId: 'ver-2026-04-draft',
          catalogItemId: 'catalog-3',
          pathKey: 'machine/draft-kit',
          displayName: 'Draft Kit',
          quantityPerMachine: 1,
          workshop: 'WS-3',
        ),
      ],
      _operationOccurrences = [
        const OperationOccurrence(
          id: 'op-1',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-1',
          name: 'Cut',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
        const OperationOccurrence(
          id: 'op-2',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-2',
          name: 'Weld',
          quantityPerMachine: 1,
          workshop: 'WS-2',
        ),
        const OperationOccurrence(
          id: 'op-3',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-2',
          name: 'Paint',
          quantityPerMachine: 1,
          workshop: 'WS-2',
        ),
        const OperationOccurrence(
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
            outcome: ExecutionReportOutcome.partial,
            acceptedAt: DateTime.utc(2026, 3, 28, 10, 35),
          ),
        ],
        'task-2': const [],
      },
      _problems = [
        Problem(
          id: 'problem-1',
          machineId: 'machine-1',
          taskId: 'task-1',
          title: 'Waiting for fixture',
          type: ProblemType.equipment,
          createdAt: DateTime.utc(2026, 3, 28, 9, 45),
          status: ProblemStatus.inProgress,
        ),
      ],
      _problemMessagesByProblem = {
        'problem-1': [
          ProblemMessage(
            id: 'problem-message-1',
            problemId: 'problem-1',
            authorId: 'master-1',
            message: 'Fixture is blocked, cannot continue welding.',
            createdAt: DateTime.utc(2026, 3, 28, 9, 50),
          ),
        ],
      },
      _wipEntries = [
        WipEntry(
          id: 'wip-1',
          machineId: 'machine-1',
          versionId: 'ver-2026-03',
          structureOccurrenceId: 'occ-1',
          operationOccurrenceId: 'op-1',
          balanceQuantity: 6,
          taskId: 'task-1',
          sourceReportId: 'report-1',
          sourceOutcome: ExecutionReportOutcome.partial,
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
      _structureSequence = 3,
      _operationSequence = 4,
      _planSequence = 1,
      _planItemSequence = 2,
      _taskSequence = 2,
      _reportSequence = 1,
      _problemSequence = 1,
      _problemMessageSequence = 1,
      _auditSequence = 1;

  final List<Machine> _machines;
  final List<MachineVersion> _versions;
  final List<StructureOccurrence> _structureOccurrences;
  final List<OperationOccurrence> _operationOccurrences;
  final List<Plan> _plans;
  final List<ProductionTask> _tasks;
  final Map<String, List<ExecutionReport>> _reportsByTask;
  final List<Problem> _problems;
  final Map<String, List<ProblemMessage>> _problemMessagesByProblem;
  final List<WipEntry> _wipEntries;
  final List<AuditEntry> _auditEntries;
  final Map<String, _StoredPlanCommand> _planByCreateRequestId = {};
  final Map<String, _StoredReleaseCommand> _releaseByRequestId = {};
  final Map<String, _StoredCompleteCommand> _completionByRequestId = {};
  final Map<String, _StoredExecutionReportCommand> _reportByRequestId = {};
  final Map<String, _StoredProblemCommand> _problemByCreateRequestId = {};
  final Map<String, _StoredProblemMessageCommand> _problemMessageByRequestId =
      {};
  final Map<String, _StoredProblemTransitionCommand>
  _problemTransitionByRequestId = {};
  final Map<String, _StoredMachineVersionCommand> _draftVersionByRequestId = {};
  final Map<String, _StoredMachineVersionCommand> _publishVersionByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _structureCreateByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _structureUpdateByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _structureDeleteByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _operationCreateByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _operationUpdateByRequestId =
      {};
  final Map<String, _StoredMachineVersionCommand> _operationDeleteByRequestId =
      {};
  int _machineSequence;
  int _versionSequence;
  int _structureSequence;
  int _operationSequence;
  int _planSequence;
  int _planItemSequence;
  int _taskSequence;
  int _reportSequence;
  int _problemSequence;
  int _problemMessageSequence;
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

  MachineVersionDetail getMachineVersionDetail(
    String machineId,
    String versionId,
  ) {
    final version = _getVersion(machineId, versionId);
    final machine = getMachine(machineId);
    return MachineVersionDetail(
      version: version,
      isActiveVersion: machine.activeVersionId == version.id,
      structureOccurrences: listStructureOccurrences(versionId),
      operationOccurrences: listOperationOccurrences(versionId),
    );
  }

  List<StructureOccurrence> listStructureOccurrences(String versionId) {
    return List.unmodifiable(
      _structureOccurrences.where((item) => item.versionId == versionId),
    );
  }

  List<OperationOccurrence> listOperationOccurrences(String versionId) {
    return List.unmodifiable(
      _operationOccurrences.where((item) => item.versionId == versionId),
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

  MachineVersion createDraftMachineVersion(
    CreateDraftMachineVersionCommand command,
  ) {
    _validateCreateDraftMachineVersionCommand(command);
    final requestSignature =
        '${command.machineId}::${command.sourceVersionId}::${command.createdBy}';
    final existing = _draftVersionByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'version_request_replayed_with_different_payload',
          'Version draft requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final sourceVersion = _getVersion(
      command.machineId,
      command.sourceVersionId,
    );
    final sourceOccurrences = listStructureOccurrences(sourceVersion.id);
    final sourceOperations = listOperationOccurrences(sourceVersion.id);
    final newVersionId =
        'ver-${DateTime.now().toUtc().year}-${++_versionSequence}-draft';
    final draftVersion = MachineVersion(
      id: newVersionId,
      machineId: command.machineId,
      label: '${sourceVersion.label}-draft-${_versionSequence}',
      createdAt: DateTime.now().toUtc(),
      status: MachineVersionStatus.draft,
    );
    _versions.add(draftVersion);

    final occurrenceIdMap = <String, String>{};
    for (final occurrence in sourceOccurrences) {
      occurrenceIdMap[occurrence.id] = 'occ-${++_structureSequence}';
    }
    for (final occurrence in sourceOccurrences) {
      _structureOccurrences.add(
        StructureOccurrence(
          id: occurrenceIdMap[occurrence.id]!,
          versionId: draftVersion.id,
          catalogItemId: occurrence.catalogItemId,
          pathKey: occurrence.pathKey,
          displayName: occurrence.displayName,
          quantityPerMachine: occurrence.quantityPerMachine,
          parentOccurrenceId: occurrence.parentOccurrenceId == null
              ? null
              : occurrenceIdMap[occurrence.parentOccurrenceId!],
          workshop: occurrence.workshop,
        ),
      );
    }
    for (final operation in sourceOperations) {
      _operationOccurrences.add(
        OperationOccurrence(
          id: 'op-${++_operationSequence}',
          versionId: draftVersion.id,
          structureOccurrenceId:
              occurrenceIdMap[operation.structureOccurrenceId] ??
              operation.structureOccurrenceId,
          name: operation.name,
          quantityPerMachine: operation.quantityPerMachine,
          workshop: operation.workshop,
        ),
      );
    }
    _rebuildVersionPaths(draftVersion.id);
    _draftVersionByRequestId[command.requestId] = _StoredMachineVersionCommand(
      signature: requestSignature,
      versionId: draftVersion.id,
    );
    _appendAudit(
      entityType: 'machine_version',
      entityId: draftVersion.id,
      action: AuditAction.created,
      changedBy: command.createdBy,
      field: 'status',
      beforeValue: '',
      afterValue: draftVersion.status.name,
    );
    return draftVersion;
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

  CompletionDecision getPlanCompletionDecision(String planId) {
    final plan = getPlan(planId);
    final planTasks = _listTasksForPlan(planId);
    final planTaskIds = planTasks.map((task) => task.id).toSet();
    final planProblems = _problems
        .where(
          (problem) =>
              problem.taskId != null && planTaskIds.contains(problem.taskId),
        )
        .toList(growable: false);
    final planWipEntries = _wipEntries
        .where(
          (entry) => entry.taskId != null && planTaskIds.contains(entry.taskId),
        )
        .toList(growable: false);
    return const CompletionPolicy().evaluate(
      tasks: planTasks,
      problems: planProblems,
      wipEntries: planWipEntries,
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

  OperationOccurrence getOperationOccurrence(String operationOccurrenceId) {
    return _operationOccurrences.firstWhere(
      (operation) => operation.id == operationOccurrenceId,
      orElse: () => throw const DemoStoreNotFound(
        'operation_occurrence_not_found',
        'Operation occurrence was not found.',
      ),
    );
  }

  Plan getPlanByItemId(String planItemId) {
    return _plans.firstWhere(
      (plan) => plan.items.any((item) => item.id == planItemId),
      orElse: () => throw const DemoStoreNotFound(
        'plan_item_not_found',
        'Plan item was not found.',
      ),
    );
  }

  MachineVersion updateStructureOccurrence(
    UpdateStructureOccurrenceCommand command,
  ) {
    _validateUpdateStructureOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.occurrenceId}::${command.displayName}::${command.quantityPerMachine}::${command.workshop ?? ''}';
    final existing = _structureUpdateByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'structure_request_replayed_with_different_payload',
          'Structure update requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    final occurrenceIndex = _structureOccurrences.indexWhere(
      (occurrence) =>
          occurrence.id == command.occurrenceId &&
          occurrence.versionId == command.versionId,
    );
    if (occurrenceIndex == -1) {
      throw const DemoStoreNotFound(
        'structure_occurrence_not_found',
        'Structure occurrence was not found.',
      );
    }

    final existingOccurrence = _structureOccurrences[occurrenceIndex];
    _structureOccurrences[occurrenceIndex] = StructureOccurrence(
      id: existingOccurrence.id,
      versionId: existingOccurrence.versionId,
      catalogItemId: existingOccurrence.catalogItemId,
      pathKey: existingOccurrence.pathKey,
      displayName: command.displayName.trim(),
      quantityPerMachine: command.quantityPerMachine,
      parentOccurrenceId: existingOccurrence.parentOccurrenceId,
      workshop: command.workshop?.trim().isEmpty ?? true
          ? null
          : command.workshop?.trim(),
    );
    _rebuildVersionPaths(command.versionId);
    _structureUpdateByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'structure_occurrence',
      entityId: existingOccurrence.id,
      action: AuditAction.updated,
      changedBy: command.changedBy,
      field: 'displayName',
      beforeValue: existingOccurrence.displayName,
      afterValue: command.displayName.trim(),
    );
    return version;
  }

  MachineVersion createStructureOccurrence(
    CreateStructureOccurrenceCommand command,
  ) {
    _validateCreateStructureOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.parentOccurrenceId ?? ''}::${command.displayName}::${command.quantityPerMachine}::${command.workshop ?? ''}';
    final existing = _structureCreateByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'structure_request_replayed_with_different_payload',
          'Structure create requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    if (command.parentOccurrenceId != null) {
      final parent = getStructureOccurrence(command.parentOccurrenceId!);
      if (parent.versionId != version.id) {
        throw DemoStoreValidation(
          'structure_occurrence_version_mismatch',
          'Parent structure occurrence does not belong to the selected draft version.',
          details: {
            'parentOccurrenceId': command.parentOccurrenceId,
            'versionId': version.id,
          },
        );
      }
    }

    final occurrence = StructureOccurrence(
      id: 'occ-${++_structureSequence}',
      versionId: version.id,
      catalogItemId: 'catalog-draft-${_structureSequence}',
      pathKey: '',
      displayName: command.displayName.trim(),
      quantityPerMachine: command.quantityPerMachine,
      parentOccurrenceId: command.parentOccurrenceId,
      workshop: command.workshop?.trim().isEmpty ?? true
          ? null
          : command.workshop?.trim(),
    );
    _structureOccurrences.add(occurrence);
    _rebuildVersionPaths(version.id);
    _structureCreateByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'structure_occurrence',
      entityId: occurrence.id,
      action: AuditAction.created,
      changedBy: command.createdBy,
      field: 'displayName',
      beforeValue: '',
      afterValue: occurrence.displayName,
    );
    return version;
  }

  MachineVersion deleteStructureOccurrence(
    DeleteStructureOccurrenceCommand command,
  ) {
    _validateDeleteStructureOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.occurrenceId}';
    final existing = _structureDeleteByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'structure_request_replayed_with_different_payload',
          'Structure delete requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    final target = _structureOccurrences.firstWhere(
      (occurrence) =>
          occurrence.id == command.occurrenceId &&
          occurrence.versionId == command.versionId,
      orElse: () => throw const DemoStoreNotFound(
        'structure_occurrence_not_found',
        'Structure occurrence was not found.',
      ),
    );
    final toDelete = _collectDescendantOccurrenceIds(version.id, target.id);
    toDelete.add(target.id);
    _structureOccurrences.removeWhere(
      (occurrence) =>
          occurrence.versionId == version.id &&
          toDelete.contains(occurrence.id),
    );
    _operationOccurrences.removeWhere(
      (operation) =>
          operation.versionId == version.id &&
          toDelete.contains(operation.structureOccurrenceId),
    );
    _rebuildVersionPaths(version.id);
    _structureDeleteByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'structure_occurrence',
      entityId: target.id,
      action: AuditAction.archived,
      changedBy: command.deletedBy,
      field: 'displayName',
      beforeValue: target.displayName,
      afterValue: '',
    );
    return version;
  }

  MachineVersion createOperationOccurrence(
    CreateOperationOccurrenceCommand command,
  ) {
    _validateCreateOperationOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.structureOccurrenceId}::${command.name}::${command.quantityPerMachine}::${command.workshop ?? ''}';
    final existing = _operationCreateByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'operation_request_replayed_with_different_payload',
          'Operation create requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    final occurrence = getStructureOccurrence(command.structureOccurrenceId);
    if (occurrence.versionId != version.id) {
      throw DemoStoreValidation(
        'structure_occurrence_version_mismatch',
        'Operation target occurrence does not belong to the selected draft version.',
        details: {
          'structureOccurrenceId': command.structureOccurrenceId,
          'versionId': version.id,
        },
      );
    }

    final operation = OperationOccurrence(
      id: 'op-${++_operationSequence}',
      versionId: version.id,
      structureOccurrenceId: occurrence.id,
      name: command.name.trim(),
      quantityPerMachine: command.quantityPerMachine,
      workshop: command.workshop?.trim().isEmpty ?? true
          ? occurrence.workshop
          : command.workshop?.trim(),
    );
    _operationOccurrences.add(operation);
    _operationCreateByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'operation_occurrence',
      entityId: operation.id,
      action: AuditAction.created,
      changedBy: command.createdBy,
      field: 'name',
      beforeValue: '',
      afterValue: operation.name,
    );
    return version;
  }

  MachineVersion updateOperationOccurrence(
    UpdateOperationOccurrenceCommand command,
  ) {
    _validateUpdateOperationOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.operationId}::${command.name}::${command.quantityPerMachine}::${command.workshop ?? ''}';
    final existing = _operationUpdateByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'operation_request_replayed_with_different_payload',
          'Operation update requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    final operationIndex = _operationOccurrences.indexWhere(
      (operation) =>
          operation.id == command.operationId &&
          operation.versionId == command.versionId,
    );
    if (operationIndex == -1) {
      throw const DemoStoreNotFound(
        'operation_occurrence_not_found',
        'Operation occurrence was not found.',
      );
    }
    final existingOperation = _operationOccurrences[operationIndex];
    _operationOccurrences[operationIndex] = OperationOccurrence(
      id: existingOperation.id,
      versionId: existingOperation.versionId,
      structureOccurrenceId: existingOperation.structureOccurrenceId,
      name: command.name.trim(),
      quantityPerMachine: command.quantityPerMachine,
      workshop: command.workshop?.trim().isEmpty ?? true
          ? existingOperation.workshop
          : command.workshop?.trim(),
    );
    _operationUpdateByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'operation_occurrence',
      entityId: existingOperation.id,
      action: AuditAction.updated,
      changedBy: command.changedBy,
      field: 'name',
      beforeValue: existingOperation.name,
      afterValue: command.name.trim(),
    );
    return version;
  }

  MachineVersion deleteOperationOccurrence(
    DeleteOperationOccurrenceCommand command,
  ) {
    _validateDeleteOperationOccurrenceCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.operationId}';
    final existing = _operationDeleteByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'operation_request_replayed_with_different_payload',
          'Operation delete requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final version = _requireDraftVersion(command.machineId, command.versionId);
    final operation = _operationOccurrences.firstWhere(
      (item) => item.id == command.operationId && item.versionId == version.id,
      orElse: () => throw const DemoStoreNotFound(
        'operation_occurrence_not_found',
        'Operation occurrence was not found.',
      ),
    );
    _operationOccurrences.removeWhere(
      (item) => item.id == operation.id && item.versionId == version.id,
    );
    _operationDeleteByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: version.id,
        );
    _appendAudit(
      entityType: 'operation_occurrence',
      entityId: operation.id,
      action: AuditAction.archived,
      changedBy: command.deletedBy,
      field: 'name',
      beforeValue: operation.name,
      afterValue: '',
    );
    return version;
  }

  MachineVersion publishMachineVersion(PublishMachineVersionCommand command) {
    _validatePublishMachineVersionCommand(command);
    final requestSignature =
        '${command.machineId}::${command.versionId}::${command.publishedBy}';
    final existing = _publishVersionByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'version_request_replayed_with_different_payload',
          'Version publish requestId was already used with different payload.',
        );
      }
      return _getVersion(command.machineId, existing.versionId);
    }

    final versionIndex = _versions.indexWhere(
      (version) =>
          version.id == command.versionId &&
          version.machineId == command.machineId,
    );
    if (versionIndex == -1) {
      throw const DemoStoreNotFound(
        'machine_version_not_found',
        'Machine version was not found.',
      );
    }
    final version = _versions[versionIndex];
    if (version.status != MachineVersionStatus.draft) {
      throw DemoStoreConflict(
        'machine_version_publish_not_allowed',
        'Only draft machine versions can be published.',
        details: {
          'versionId': command.versionId,
          'status': version.status.name,
        },
      );
    }

    final published = MachineVersion(
      id: version.id,
      machineId: version.machineId,
      label: version.label,
      createdAt: version.createdAt,
      status: MachineVersionStatus.published,
    );
    _versions[versionIndex] = published;
    final machineIndex = _machines.indexWhere(
      (machine) => machine.id == command.machineId,
    );
    final machine = _machines[machineIndex];
    _machines[machineIndex] = Machine(
      id: machine.id,
      code: machine.code,
      name: machine.name,
      activeVersionId: published.id,
    );
    _publishVersionByRequestId[command.requestId] =
        _StoredMachineVersionCommand(
          signature: requestSignature,
          versionId: published.id,
        );
    _appendAudit(
      entityType: 'machine_version',
      entityId: published.id,
      action: AuditAction.updated,
      changedBy: command.publishedBy,
      field: 'status',
      beforeValue: version.status.name,
      afterValue: published.status.name,
    );
    return published;
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
            requiredQuantity:
                item.requestedQuantity * operation.quantityPerMachine,
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

  CompletePlanResult completePlan(CompletePlanCommand command) {
    _validateCompletePlanCommand(command);
    final requestSignature = '${command.planId}::${command.completedBy}';
    final existing = _completionByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'plan_request_replayed_with_different_payload',
          'Plan completion requestId was already used with different payload.',
        );
      }
      return existing.result;
    }

    final planIndex = _plans.indexWhere((plan) => plan.id == command.planId);
    if (planIndex == -1) {
      throw const DemoStoreNotFound('plan_not_found', 'Plan was not found.');
    }

    final plan = _plans[planIndex];
    if (plan.status != PlanStatus.released) {
      throw DemoStoreConflict(
        'plan_completion_not_allowed',
        'Only released plans can be completed.',
        details: {'planId': command.planId, 'status': plan.status.name},
      );
    }

    final decision = getPlanCompletionDecision(command.planId);
    if (!decision.canComplete) {
      throw DemoStoreConflict(
        'plan_completion_blocked',
        'Plan completion is blocked by open tasks, problems, or WIP.',
        details: {
          'planId': command.planId,
          'blockers': decision.blockers
              .map(
                (blocker) => {
                  'type': blocker.type.name,
                  'entityIds': blocker.entityIds,
                },
              )
              .toList(growable: false),
        },
      );
    }

    final completedPlan = Plan(
      id: plan.id,
      machineId: plan.machineId,
      versionId: plan.versionId,
      title: plan.title,
      createdAt: plan.createdAt,
      items: plan.items,
      status: PlanStatus.completed,
      revisions: plan.revisions,
    );
    _plans[planIndex] = completedPlan;
    _appendPlanAudit(
      entityId: completedPlan.id,
      changedBy: command.completedBy,
      field: 'status',
      beforeValue: plan.status.name,
      afterValue: completedPlan.status.name,
    );

    final result = CompletePlanResult(
      planId: completedPlan.id,
      status: completedPlan.status,
    );
    _completionByRequestId[command.requestId] = _StoredCompleteCommand(
      signature: requestSignature,
      result: result,
    );
    return result;
  }

  List<ProductionTask> listTasks({String? assigneeId, String? status}) {
    var tasks = _tasks.where((task) {
      if (assigneeId != null &&
          assigneeId.isNotEmpty &&
          task.assigneeId != assigneeId) {
        return false;
      }
      if (status != null && status.isNotEmpty && task.status.name != status) {
        return false;
      }
      return true;
    });
    return List.unmodifiable(tasks);
  }

  List<ProductionTask> _listTasksForPlan(String planId) {
    final plan = getPlan(planId);
    final planItemIds = plan.items.map((item) => item.id).toSet();
    return _tasks
        .where((task) => planItemIds.contains(task.planItemId))
        .toList(growable: false);
  }

  ProductionTask getTask(String taskId) {
    return _tasks.firstWhere(
      (task) => task.id == taskId,
      orElse: () => throw const DemoStoreNotFound(
        'task_not_found',
        'Task was not found.',
      ),
    );
  }

  List<ExecutionReport> listReports(String taskId) {
    getTask(taskId);

    return List.unmodifiable(_reportsByTask[taskId] ?? const []);
  }

  double reportedQuantityForTask(String taskId) {
    return listReports(taskId)
        .where((report) => report.isAccepted)
        .fold(0.0, (sum, report) => sum + report.reportedQuantity);
  }

  CreateExecutionReportResult createExecutionReport(
    CreateExecutionReportCommand command,
  ) {
    _validateCreateExecutionReportCommand(command);
    final requestSignature = _buildCreateExecutionReportSignature(command);
    final existing = _reportByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'execution_report_replayed_with_different_payload',
          'Execution report requestId was already used with different payload.',
        );
      }
      return existing.result;
    }

    final taskIndex = _tasks.indexWhere((task) => task.id == command.taskId);
    if (taskIndex == -1) {
      throw const DemoStoreNotFound('task_not_found', 'Task was not found.');
    }

    final task = _tasks[taskIndex];
    if (task.isClosed) {
      throw DemoStoreConflict(
        'task_report_not_allowed',
        'Closed task cannot accept new execution reports.',
        details: {'taskId': command.taskId, 'status': task.status.name},
      );
    }

    final currentReported = reportedQuantityForTask(command.taskId);
    final remainingBefore = task.requiredQuantity - currentReported;
    _validateExecutionReportOutcome(
      command: command,
      task: task,
      remainingBefore: remainingBefore,
    );
    final nextReported = currentReported + command.reportedQuantity;

    final report = ExecutionReport(
      id: 'report-${++_reportSequence}',
      taskId: command.taskId,
      reportedBy: command.reportedBy,
      reportedAt: DateTime.now().toUtc(),
      reportedQuantity: command.reportedQuantity,
      outcome: command.outcome,
      reason: command.reason,
      acceptedAt: DateTime.now().toUtc(),
    );
    final reports = [...(_reportsByTask[command.taskId] ?? const []), report];
    _reportsByTask[command.taskId] = List.unmodifiable(reports);

    final nextStatus = nextReported >= task.requiredQuantity
        ? TaskStatus.completed
        : (nextReported > 0 ||
              command.outcome == ExecutionReportOutcome.notCompleted)
        ? TaskStatus.inProgress
        : TaskStatus.pending;
    final updatedTask = ProductionTask(
      id: task.id,
      planItemId: task.planItemId,
      operationOccurrenceId: task.operationOccurrenceId,
      requiredQuantity: task.requiredQuantity,
      assigneeId: task.assigneeId,
      status: nextStatus,
    );
    _tasks[taskIndex] = updatedTask;

    _appendAudit(
      entityType: 'execution_report',
      entityId: report.id,
      action: AuditAction.created,
      changedBy: command.reportedBy,
      field: 'reportedQuantity',
      beforeValue: '',
      afterValue: command.reportedQuantity.toString(),
    );
    if (task.status != updatedTask.status) {
      _appendAudit(
        entityType: 'task',
        entityId: task.id,
        action: AuditAction.updated,
        changedBy: command.reportedBy,
        field: 'status',
        beforeValue: task.status.name,
        afterValue: updatedTask.status.name,
      );
    }

    final wipEffect = _applyExecutionReportWipEffect(
      task: updatedTask,
      report: report,
      reportedQuantityTotal: nextReported,
    );

    final result = CreateExecutionReportResult(
      report: report,
      taskStatus: updatedTask.status,
      reportedQuantityTotal: nextReported,
      remainingQuantity: max(0.0, task.requiredQuantity - nextReported),
      wipEffect: wipEffect,
    );
    _reportByRequestId[command.requestId] = _StoredExecutionReportCommand(
      signature: requestSignature,
      result: result,
    );
    return result;
  }

  List<Problem> listProblems({String? taskId, String? status}) {
    final problems = _problems.where((problem) {
      if (taskId != null && taskId.isNotEmpty && problem.taskId != taskId) {
        return false;
      }
      if (status != null &&
          status.isNotEmpty &&
          problem.status.name != status) {
        return false;
      }
      return true;
    });
    return List.unmodifiable(problems);
  }

  Problem getProblem(String problemId) {
    return _problems.firstWhere(
      (problem) => problem.id == problemId,
      orElse: () => throw const DemoStoreNotFound(
        'problem_not_found',
        'Problem was not found.',
      ),
    );
  }

  List<ProblemMessage> listProblemMessages(String problemId) {
    getProblem(problemId);
    return List.unmodifiable(_problemMessagesByProblem[problemId] ?? const []);
  }

  int problemMessageCount(String problemId) =>
      listProblemMessages(problemId).length;

  Problem createProblem(CreateProblemCommand command) {
    _validateCreateProblemCommand(command);
    final requestSignature = _buildCreateProblemSignature(command);
    final existing = _problemByCreateRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'problem_request_replayed_with_different_payload',
          'Problem create requestId was already used with different payload.',
        );
      }
      return getProblem(existing.problemId);
    }

    final task = getTask(command.taskId);
    final plan = getPlanByItemId(task.planItemId);
    final problem = Problem(
      id: 'problem-${++_problemSequence}',
      machineId: plan.machineId,
      taskId: task.id,
      title: command.title.trim(),
      type: command.type,
      createdAt: DateTime.now().toUtc(),
      status: ProblemStatus.open,
    );
    final firstMessage = ProblemMessage(
      id: 'problem-message-${++_problemMessageSequence}',
      problemId: problem.id,
      authorId: command.createdBy,
      message: command.description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    _problems.add(problem);
    _problemMessagesByProblem[problem.id] = [firstMessage];
    _problemByCreateRequestId[command.requestId] = _StoredProblemCommand(
      signature: requestSignature,
      problemId: problem.id,
    );
    _appendAudit(
      entityType: 'problem',
      entityId: problem.id,
      action: AuditAction.created,
      changedBy: command.createdBy,
      field: 'status',
      beforeValue: '',
      afterValue: problem.status.name,
    );
    _appendAudit(
      entityType: 'problem_message',
      entityId: firstMessage.id,
      action: AuditAction.created,
      changedBy: command.createdBy,
      field: 'message',
      beforeValue: '',
      afterValue: firstMessage.message,
    );
    return problem;
  }

  ProblemMessage addProblemMessage(AddProblemMessageCommand command) {
    _validateAddProblemMessageCommand(command);
    final requestSignature = _buildAddProblemMessageSignature(command);
    final existing = _problemMessageByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'problem_request_replayed_with_different_payload',
          'Problem message requestId was already used with different payload.',
        );
      }
      return _getProblemMessage(existing.problemId, existing.messageId);
    }

    final problem = getProblem(command.problemId);
    if (!problem.isOpen) {
      throw DemoStoreValidation(
        'problem_message_not_allowed',
        'Closed problem does not accept new messages.',
        details: {
          'problemId': command.problemId,
          'status': problem.status.name,
        },
      );
    }

    final message = ProblemMessage(
      id: 'problem-message-${++_problemMessageSequence}',
      problemId: command.problemId,
      authorId: command.authorId,
      message: command.message.trim(),
      createdAt: DateTime.now().toUtc(),
    );
    final messages = [
      ...(_problemMessagesByProblem[command.problemId] ?? const []),
      message,
    ];
    _problemMessagesByProblem[command.problemId] = List.unmodifiable(messages);
    _problemMessageByRequestId[command.requestId] =
        _StoredProblemMessageCommand(
          signature: requestSignature,
          problemId: command.problemId,
          messageId: message.id,
        );
    _appendAudit(
      entityType: 'problem_message',
      entityId: message.id,
      action: AuditAction.created,
      changedBy: command.authorId,
      field: 'message',
      beforeValue: '',
      afterValue: message.message,
    );
    return message;
  }

  Problem transitionProblem(TransitionProblemCommand command) {
    _validateTransitionProblemCommand(command);
    final requestSignature = _buildTransitionProblemSignature(command);
    final existing = _problemTransitionByRequestId[command.requestId];
    if (existing != null) {
      if (existing.signature != requestSignature) {
        throw const DemoStoreConflict(
          'problem_request_replayed_with_different_payload',
          'Problem transition requestId was already used with different payload.',
        );
      }
      return getProblem(existing.problemId);
    }

    final problemIndex = _problems.indexWhere(
      (problem) => problem.id == command.problemId,
    );
    if (problemIndex == -1) {
      throw const DemoStoreNotFound(
        'problem_not_found',
        'Problem was not found.',
      );
    }
    final problem = _problems[problemIndex];
    if (!_canTransitionProblem(problem.status, command.toStatus)) {
      throw DemoStoreConflict(
        'problem_transition_not_allowed',
        'Problem transition is not allowed for the current lifecycle state.',
        details: {
          'problemId': command.problemId,
          'status': problem.status.name,
          'toStatus': command.toStatus.name,
        },
      );
    }

    final updatedProblem = Problem(
      id: problem.id,
      machineId: problem.machineId,
      taskId: problem.taskId,
      title: problem.title,
      type: problem.type,
      createdAt: problem.createdAt,
      status: command.toStatus,
    );
    _problems[problemIndex] = updatedProblem;
    _problemTransitionByRequestId[command.requestId] =
        _StoredProblemTransitionCommand(
          signature: requestSignature,
          problemId: updatedProblem.id,
        );
    _appendAudit(
      entityType: 'problem',
      entityId: updatedProblem.id,
      action: AuditAction.updated,
      changedBy: command.changedBy,
      field: 'status',
      beforeValue: problem.status.name,
      afterValue: updatedProblem.status.name,
    );
    return updatedProblem;
  }

  List<WipEntry> listWipEntries() => List.unmodifiable(_wipEntries);

  List<AuditEntry> listAuditEntries() => List.unmodifiable(_auditEntries);

  String? planIdForTask(String? taskId) {
    if (taskId == null || taskId.isEmpty) {
      return null;
    }
    final task = getTask(taskId);
    return getPlanByItemId(task.planItemId).id;
  }

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
      throw const DemoStoreNotFound(
        'machine_not_found',
        'Machine was not found.',
      );
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

  MachineVersion _requireDraftVersion(String machineId, String versionId) {
    final version = _getVersion(machineId, versionId);
    if (version.status != MachineVersionStatus.draft) {
      throw DemoStoreConflict(
        'machine_version_edit_not_allowed',
        'Only draft machine versions can be edited.',
        details: {'versionId': versionId, 'status': version.status.name},
      );
    }
    return version;
  }

  Set<String> _collectDescendantOccurrenceIds(String versionId, String rootId) {
    final descendants = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final occurrence in _structureOccurrences) {
        if (occurrence.versionId != versionId ||
            occurrence.parentOccurrenceId == null) {
          continue;
        }
        if (occurrence.parentOccurrenceId == rootId ||
            descendants.contains(occurrence.parentOccurrenceId)) {
          if (descendants.add(occurrence.id)) {
            changed = true;
          }
        }
      }
    }
    return descendants;
  }

  void _rebuildVersionPaths(String versionId) {
    final versionOccurrences = _structureOccurrences
        .where((occurrence) => occurrence.versionId == versionId)
        .toList(growable: false);
    if (versionOccurrences.isEmpty) {
      return;
    }

    final byParent = <String?, List<StructureOccurrence>>{};
    for (final occurrence in versionOccurrences) {
      byParent
          .putIfAbsent(occurrence.parentOccurrenceId, () => [])
          .add(occurrence);
    }
    final rebuilt = <String, StructureOccurrence>{};

    void rebuild(String? parentId, String parentPath) {
      final children = [
        ...(byParent[parentId] ?? const <StructureOccurrence>[]),
      ];
      children.sort((left, right) {
        final nameCompare = left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
      final usedSegments = <String>{};
      for (final child in children) {
        final segmentBase = _slugSegment(child.displayName, fallback: child.id);
        var segment = segmentBase;
        var suffix = 2;
        while (!usedSegments.add(segment)) {
          segment = '$segmentBase-$suffix';
          suffix += 1;
        }
        final pathKey = parentPath.isEmpty
            ? 'machine/$segment'
            : '$parentPath/$segment';
        rebuilt[child.id] = StructureOccurrence(
          id: child.id,
          versionId: child.versionId,
          catalogItemId: child.catalogItemId,
          pathKey: pathKey,
          displayName: child.displayName,
          quantityPerMachine: child.quantityPerMachine,
          parentOccurrenceId: child.parentOccurrenceId,
          workshop: child.workshop,
        );
        rebuild(child.id, pathKey);
      }
    }

    rebuild(null, '');
    for (var index = 0; index < _structureOccurrences.length; index += 1) {
      final occurrence = _structureOccurrences[index];
      if (occurrence.versionId != versionId) {
        continue;
      }
      _structureOccurrences[index] = rebuilt[occurrence.id] ?? occurrence;
    }
  }

  String _slugSegment(String value, {required String fallback}) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    final compact = normalized.replaceAll(RegExp(r'-{2,}'), '-');
    final trimmed = compact.replaceAll(RegExp(r'^-|-$'), '');
    return trimmed.isEmpty ? fallback.toLowerCase() : trimmed;
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

  void _validateCreateDraftMachineVersionCommand(
    CreateDraftMachineVersionCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.sourceVersionId.trim().isEmpty ||
        command.createdBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, sourceVersionId, and createdBy are required.',
      );
    }
  }

  void _validateCreateStructureOccurrenceCommand(
    CreateStructureOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.createdBy.trim().isEmpty ||
        command.displayName.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, createdBy, and displayName are required.',
      );
    }
    if (command.quantityPerMachine <= 0) {
      throw const DemoStoreValidation(
        'invalid_requested_quantity',
        'quantityPerMachine must be greater than zero.',
      );
    }
  }

  void _validateUpdateStructureOccurrenceCommand(
    UpdateStructureOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.occurrenceId.trim().isEmpty ||
        command.changedBy.trim().isEmpty ||
        command.displayName.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, occurrenceId, changedBy, and displayName are required.',
      );
    }
    if (command.quantityPerMachine <= 0) {
      throw const DemoStoreValidation(
        'invalid_requested_quantity',
        'quantityPerMachine must be greater than zero.',
      );
    }
  }

  void _validateDeleteStructureOccurrenceCommand(
    DeleteStructureOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.occurrenceId.trim().isEmpty ||
        command.deletedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, occurrenceId, and deletedBy are required.',
      );
    }
  }

  void _validateCreateOperationOccurrenceCommand(
    CreateOperationOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.structureOccurrenceId.trim().isEmpty ||
        command.createdBy.trim().isEmpty ||
        command.name.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, structureOccurrenceId, createdBy, and name are required.',
      );
    }
    if (command.quantityPerMachine <= 0) {
      throw const DemoStoreValidation(
        'invalid_requested_quantity',
        'quantityPerMachine must be greater than zero.',
      );
    }
  }

  void _validateUpdateOperationOccurrenceCommand(
    UpdateOperationOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.operationId.trim().isEmpty ||
        command.changedBy.trim().isEmpty ||
        command.name.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, operationId, changedBy, and name are required.',
      );
    }
    if (command.quantityPerMachine <= 0) {
      throw const DemoStoreValidation(
        'invalid_requested_quantity',
        'quantityPerMachine must be greater than zero.',
      );
    }
  }

  void _validateDeleteOperationOccurrenceCommand(
    DeleteOperationOccurrenceCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.operationId.trim().isEmpty ||
        command.deletedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, operationId, and deletedBy are required.',
      );
    }
  }

  void _validatePublishMachineVersionCommand(
    PublishMachineVersionCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.machineId.trim().isEmpty ||
        command.versionId.trim().isEmpty ||
        command.publishedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, machineId, versionId, and publishedBy are required.',
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

  void _validateCompletePlanCommand(CompletePlanCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.planId.trim().isEmpty ||
        command.completedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, planId, and completedBy are required.',
      );
    }
  }

  void _validateCreateExecutionReportCommand(
    CreateExecutionReportCommand command,
  ) {
    if (command.requestId.trim().isEmpty ||
        command.taskId.trim().isEmpty ||
        command.reportedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, taskId, and reportedBy are required.',
      );
    }
    if (command.reportedQuantity < 0) {
      throw const DemoStoreValidation(
        'invalid_reported_quantity',
        'reportedQuantity must be zero or greater.',
      );
    }
  }

  void _validateCreateProblemCommand(CreateProblemCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.taskId.trim().isEmpty ||
        command.createdBy.trim().isEmpty ||
        command.title.trim().isEmpty ||
        command.description.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, taskId, createdBy, title, and description are required.',
      );
    }
  }

  void _validateAddProblemMessageCommand(AddProblemMessageCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.problemId.trim().isEmpty ||
        command.authorId.trim().isEmpty ||
        command.message.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_problem_message',
        'requestId, problemId, authorId, and message are required.',
      );
    }
  }

  void _validateTransitionProblemCommand(TransitionProblemCommand command) {
    if (command.requestId.trim().isEmpty ||
        command.problemId.trim().isEmpty ||
        command.changedBy.trim().isEmpty) {
      throw const DemoStoreValidation(
        'invalid_request',
        'requestId, problemId, and changedBy are required.',
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

  String _buildCreateExecutionReportSignature(
    CreateExecutionReportCommand command,
  ) {
    return '${command.taskId}::${command.reportedBy}::${command.reportedQuantity}::${command.outcome.name}::${command.reason ?? ''}';
  }

  void _validateExecutionReportOutcome({
    required CreateExecutionReportCommand command,
    required ProductionTask task,
    required double remainingBefore,
  }) {
    switch (command.outcome) {
      case ExecutionReportOutcome.completed:
        if (remainingBefore <= 0 ||
            command.reportedQuantity != remainingBefore) {
          throw DemoStoreValidation(
            'invalid_report_outcome',
            'Completed outcome must exactly match the remaining task quantity.',
            details: {
              'taskId': task.id,
              'remainingQuantity': remainingBefore,
              'reportedQuantity': command.reportedQuantity,
              'outcome': command.outcome.name,
            },
          );
        }
        break;
      case ExecutionReportOutcome.partial:
        if (command.reportedQuantity <= 0 ||
            command.reportedQuantity >= remainingBefore) {
          throw DemoStoreValidation(
            'invalid_report_outcome',
            'Partial outcome must report a positive quantity below the remaining task quantity.',
            details: {
              'taskId': task.id,
              'remainingQuantity': remainingBefore,
              'reportedQuantity': command.reportedQuantity,
              'outcome': command.outcome.name,
            },
          );
        }
        if (command.reason == null || command.reason!.trim().isEmpty) {
          throw const DemoStoreValidation(
            'invalid_report_reason',
            'Partial outcome requires a reason.',
          );
        }
        break;
      case ExecutionReportOutcome.notCompleted:
        if (command.reportedQuantity != 0) {
          throw DemoStoreValidation(
            'invalid_report_outcome',
            'Not completed outcome must keep reportedQuantity at zero.',
            details: {
              'taskId': task.id,
              'remainingQuantity': remainingBefore,
              'reportedQuantity': command.reportedQuantity,
              'outcome': command.outcome.name,
            },
          );
        }
        if (command.reason == null || command.reason!.trim().isEmpty) {
          throw const DemoStoreValidation(
            'invalid_report_reason',
            'Not completed outcome requires a reason.',
          );
        }
        break;
      case ExecutionReportOutcome.overrun:
        if (command.reportedQuantity <= remainingBefore) {
          throw DemoStoreValidation(
            'invalid_report_outcome',
            'Overrun outcome must exceed the remaining task quantity.',
            details: {
              'taskId': task.id,
              'remainingQuantity': remainingBefore,
              'reportedQuantity': command.reportedQuantity,
              'outcome': command.outcome.name,
            },
          );
        }
        break;
    }
  }

  ExecutionReportWipEffect _applyExecutionReportWipEffect({
    required ProductionTask task,
    required ExecutionReport report,
    required double reportedQuantityTotal,
  }) {
    final operation = getOperationOccurrence(task.operationOccurrenceId);
    final plan = getPlanByItemId(task.planItemId);
    final balanceQuantity = switch (report.outcome) {
      ExecutionReportOutcome.completed => 0.0,
      ExecutionReportOutcome.partial || ExecutionReportOutcome.notCompleted =>
        max(0.0, task.requiredQuantity - reportedQuantityTotal),
      ExecutionReportOutcome.overrun => max(
        0.0,
        reportedQuantityTotal - task.requiredQuantity,
      ),
    };
    final existingIndex = _wipEntries.indexWhere(
      (entry) => entry.taskId == task.id && entry.status == WipEntryStatus.open,
    );

    if (balanceQuantity <= 0) {
      if (existingIndex == -1) {
        return const ExecutionReportWipEffect(type: 'none');
      }
      final existing = _wipEntries[existingIndex];
      final consumed = WipEntry(
        id: existing.id,
        machineId: existing.machineId,
        versionId: existing.versionId,
        structureOccurrenceId: existing.structureOccurrenceId,
        operationOccurrenceId: existing.operationOccurrenceId,
        balanceQuantity: 0,
        taskId: existing.taskId,
        sourceReportId: report.id,
        sourceOutcome: report.outcome,
        status: WipEntryStatus.consumed,
      );
      _wipEntries[existingIndex] = consumed;
      _appendAudit(
        entityType: 'wip_entry',
        entityId: consumed.id,
        action: AuditAction.updated,
        changedBy: report.reportedBy,
        field: 'status',
        beforeValue: existing.status.name,
        afterValue: consumed.status.name,
      );
      return ExecutionReportWipEffect(type: 'consumed', entry: consumed);
    }

    if (existingIndex == -1) {
      final created = WipEntry(
        id: 'wip-${_wipEntries.length + 1}',
        machineId: plan.machineId,
        versionId: plan.versionId,
        structureOccurrenceId: operation.structureOccurrenceId,
        operationOccurrenceId: operation.id,
        balanceQuantity: balanceQuantity,
        taskId: task.id,
        sourceReportId: report.id,
        sourceOutcome: report.outcome,
        status: WipEntryStatus.open,
      );
      _wipEntries.add(created);
      _appendAudit(
        entityType: 'wip_entry',
        entityId: created.id,
        action: AuditAction.created,
        changedBy: report.reportedBy,
        field: 'balanceQuantity',
        beforeValue: '',
        afterValue: created.balanceQuantity.toString(),
      );
      return ExecutionReportWipEffect(type: 'created', entry: created);
    }

    final existing = _wipEntries[existingIndex];
    final updated = WipEntry(
      id: existing.id,
      machineId: existing.machineId,
      versionId: existing.versionId,
      structureOccurrenceId: existing.structureOccurrenceId,
      operationOccurrenceId: existing.operationOccurrenceId,
      balanceQuantity: balanceQuantity,
      taskId: existing.taskId,
      sourceReportId: report.id,
      sourceOutcome: report.outcome,
      status: WipEntryStatus.open,
    );
    _wipEntries[existingIndex] = updated;
    _appendAudit(
      entityType: 'wip_entry',
      entityId: updated.id,
      action: AuditAction.updated,
      changedBy: report.reportedBy,
      field: 'balanceQuantity',
      beforeValue: existing.balanceQuantity.toString(),
      afterValue: updated.balanceQuantity.toString(),
    );
    return ExecutionReportWipEffect(type: 'updated', entry: updated);
  }

  String _buildCreateProblemSignature(CreateProblemCommand command) {
    return '${command.taskId}::${command.createdBy}::${command.type.name}::${command.title}::${command.description}';
  }

  String _buildAddProblemMessageSignature(AddProblemMessageCommand command) {
    return '${command.problemId}::${command.authorId}::${command.message}';
  }

  String _buildTransitionProblemSignature(TransitionProblemCommand command) {
    return '${command.problemId}::${command.changedBy}::${command.toStatus.name}';
  }

  bool _canTransitionProblem(ProblemStatus current, ProblemStatus next) {
    return switch (current) {
      ProblemStatus.open =>
        next == ProblemStatus.inProgress || next == ProblemStatus.closed,
      ProblemStatus.inProgress => next == ProblemStatus.closed,
      ProblemStatus.closed => false,
    };
  }

  ProblemMessage _getProblemMessage(String problemId, String messageId) {
    return listProblemMessages(problemId).firstWhere(
      (message) => message.id == messageId,
      orElse: () => throw const DemoStoreNotFound(
        'problem_message_not_found',
        'Problem message was not found.',
      ),
    );
  }

  void _appendPlanAudit({
    required String entityId,
    required String changedBy,
    required String field,
    required String beforeValue,
    required String afterValue,
  }) {
    _appendAudit(
      entityType: 'plan',
      entityId: entityId,
      action: AuditAction.updated,
      changedBy: changedBy,
      field: field,
      beforeValue: beforeValue,
      afterValue: afterValue,
    );
  }

  void _appendAudit({
    required String entityType,
    required String entityId,
    required AuditAction action,
    required String changedBy,
    required String field,
    required String beforeValue,
    required String afterValue,
  }) {
    _auditEntries.add(
      AuditEntry(
        id: 'audit-${++_auditSequence}',
        entityType: entityType,
        entityId: entityId,
        action: action,
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

class CompletePlanCommand {
  const CompletePlanCommand({
    required this.requestId,
    required this.planId,
    required this.completedBy,
  });

  final String requestId;
  final String planId;
  final String completedBy;
}

class CompletePlanResult {
  const CompletePlanResult({required this.planId, required this.status});

  final String planId;
  final PlanStatus status;
}

class CreateExecutionReportCommand {
  const CreateExecutionReportCommand({
    required this.requestId,
    required this.taskId,
    required this.reportedBy,
    required this.reportedQuantity,
    required this.outcome,
    this.reason,
  });

  final String requestId;
  final String taskId;
  final String reportedBy;
  final double reportedQuantity;
  final ExecutionReportOutcome outcome;
  final String? reason;
}

class CreateExecutionReportResult {
  const CreateExecutionReportResult({
    required this.report,
    required this.taskStatus,
    required this.reportedQuantityTotal,
    required this.remainingQuantity,
    required this.wipEffect,
  });

  final ExecutionReport report;
  final TaskStatus taskStatus;
  final double reportedQuantityTotal;
  final double remainingQuantity;
  final ExecutionReportWipEffect wipEffect;
}

class ExecutionReportWipEffect {
  const ExecutionReportWipEffect({required this.type, this.entry});

  final String type;
  final WipEntry? entry;
}

class CreateProblemCommand {
  const CreateProblemCommand({
    required this.requestId,
    required this.taskId,
    required this.createdBy,
    required this.type,
    required this.title,
    required this.description,
  });

  final String requestId;
  final String taskId;
  final String createdBy;
  final ProblemType type;
  final String title;
  final String description;
}

class AddProblemMessageCommand {
  const AddProblemMessageCommand({
    required this.requestId,
    required this.problemId,
    required this.authorId,
    required this.message,
  });

  final String requestId;
  final String problemId;
  final String authorId;
  final String message;
}

class TransitionProblemCommand {
  const TransitionProblemCommand({
    required this.requestId,
    required this.problemId,
    required this.changedBy,
    required this.toStatus,
  });

  final String requestId;
  final String problemId;
  final String changedBy;
  final ProblemStatus toStatus;
}

class CreateDraftMachineVersionCommand {
  const CreateDraftMachineVersionCommand({
    required this.requestId,
    required this.machineId,
    required this.sourceVersionId,
    required this.createdBy,
  });

  final String requestId;
  final String machineId;
  final String sourceVersionId;
  final String createdBy;
}

class CreateStructureOccurrenceCommand {
  const CreateStructureOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.createdBy,
    required this.displayName,
    required this.quantityPerMachine,
    this.parentOccurrenceId,
    this.workshop,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String createdBy;
  final String displayName;
  final double quantityPerMachine;
  final String? parentOccurrenceId;
  final String? workshop;
}

class UpdateStructureOccurrenceCommand {
  const UpdateStructureOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.occurrenceId,
    required this.changedBy,
    required this.displayName,
    required this.quantityPerMachine,
    this.workshop,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String occurrenceId;
  final String changedBy;
  final String displayName;
  final double quantityPerMachine;
  final String? workshop;
}

class DeleteStructureOccurrenceCommand {
  const DeleteStructureOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.occurrenceId,
    required this.deletedBy,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String occurrenceId;
  final String deletedBy;
}

class CreateOperationOccurrenceCommand {
  const CreateOperationOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.createdBy,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String createdBy;
  final String name;
  final double quantityPerMachine;
  final String? workshop;
}

class UpdateOperationOccurrenceCommand {
  const UpdateOperationOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.operationId,
    required this.changedBy,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String operationId;
  final String changedBy;
  final String name;
  final double quantityPerMachine;
  final String? workshop;
}

class DeleteOperationOccurrenceCommand {
  const DeleteOperationOccurrenceCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.operationId,
    required this.deletedBy,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String operationId;
  final String deletedBy;
}

class PublishMachineVersionCommand {
  const PublishMachineVersionCommand({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.publishedBy,
  });

  final String requestId;
  final String machineId;
  final String versionId;
  final String publishedBy;
}

class MachineVersionDetail {
  const MachineVersionDetail({
    required this.version,
    required this.isActiveVersion,
    required this.structureOccurrences,
    required this.operationOccurrences,
  });

  final MachineVersion version;
  final bool isActiveVersion;
  final List<StructureOccurrence> structureOccurrences;
  final List<OperationOccurrence> operationOccurrences;
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

class _StoredCompleteCommand {
  const _StoredCompleteCommand({required this.signature, required this.result});

  final String signature;
  final CompletePlanResult result;
}

class _StoredExecutionReportCommand {
  const _StoredExecutionReportCommand({
    required this.signature,
    required this.result,
  });

  final String signature;
  final CreateExecutionReportResult result;
}

class _StoredProblemCommand {
  const _StoredProblemCommand({
    required this.signature,
    required this.problemId,
  });

  final String signature;
  final String problemId;
}

class _StoredProblemMessageCommand {
  const _StoredProblemMessageCommand({
    required this.signature,
    required this.problemId,
    required this.messageId,
  });

  final String signature;
  final String problemId;
  final String messageId;
}

class _StoredProblemTransitionCommand {
  const _StoredProblemTransitionCommand({
    required this.signature,
    required this.problemId,
  });

  final String signature;
  final String problemId;
}

class _StoredMachineVersionCommand {
  const _StoredMachineVersionCommand({
    required this.signature,
    required this.versionId,
  });

  final String signature;
  final String versionId;
}
