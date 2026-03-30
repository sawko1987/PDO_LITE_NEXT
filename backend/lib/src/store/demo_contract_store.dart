import 'package:domain/domain.dart';

class DemoContractStore {
  DemoContractStore()
      : _machines = [
          Machine(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'ПДО-100',
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
        _plans = [
          Plan(
            id: 'plan-1',
            machineId: 'machine-1',
            versionId: 'ver-2026-03',
            title: 'Сменный план на 28.03.2026',
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
        _tasks = const [
          ProductionTask(
            id: 'task-1',
            planItemId: 'plan-item-1',
            operationOccurrenceId: 'op-1',
            requiredQuantity: 12,
            assigneeId: 'master-1',
            status: TaskStatus.inProgress,
          ),
          ProductionTask(
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
            title: 'Ожидание оснастки',
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
        _versionSequence = 2;

  final List<Machine> _machines;
  final List<MachineVersion> _versions;
  final List<Plan> _plans;
  final List<ProductionTask> _tasks;
  final Map<String, List<ExecutionReport>> _reportsByTask;
  final List<Problem> _problems;
  final List<WipEntry> _wipEntries;
  final List<AuditEntry> _auditEntries;
  int _machineSequence;
  int _versionSequence;

  List<Machine> listMachines() => List.unmodifiable(_machines);

  Machine getMachine(String machineId) {
    return _machines.firstWhere(
      (machine) => machine.id == machineId,
      orElse: () =>
          throw const DemoStoreNotFound('machine_not_found', 'Machine was not found.'),
    );
  }

  bool hasMachineCode(String machineCode) {
    return _machines.any((machine) => machine.code == machineCode);
  }

  List<MachineVersion> listVersions(String machineId) {
    final machineExists = _machines.any((machine) => machine.id == machineId);
    if (!machineExists) {
      throw const DemoStoreNotFound('machine_not_found', 'Machine was not found.');
    }

    return List.unmodifiable(
      _versions.where((version) => version.machineId == machineId),
    );
  }

  List<Plan> listPlans() => List.unmodifiable(_plans);

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
}

class DemoStoreNotFound implements Exception {
  const DemoStoreNotFound(this.code, this.message);

  final String code;
  final String message;
}
