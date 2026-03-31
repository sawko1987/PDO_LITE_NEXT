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
  final Map<String, _StoredExecutionReportCommand> _reportByRequestId = {};
  final Map<String, _StoredProblemCommand> _problemByCreateRequestId = {};
  final Map<String, _StoredProblemMessageCommand> _problemMessageByRequestId =
      {};
  final Map<String, _StoredProblemTransitionCommand>
  _problemTransitionByRequestId = {};
  int _machineSequence;
  int _versionSequence;
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
