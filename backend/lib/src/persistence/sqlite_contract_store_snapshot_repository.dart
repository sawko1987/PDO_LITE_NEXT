import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../store/contract_store_snapshot.dart';
import 'contract_store_snapshot_repository.dart';

class SqliteContractStoreSnapshotRepository
    implements ContractStoreSnapshotRepository {
  SqliteContractStoreSnapshotRepository({
    required String databasePath,
    String? packageRoot,
  }) : _databasePath = databasePath,
       _packageRoot = packageRoot;

  final String _databasePath;
  final String? _packageRoot;

  static const List<String> _tableResetOrder = [
    'catalog_items',
    'machines',
    'machine_versions',
    'structure_occurrences',
    'operation_occurrences',
    'plans',
    'plan_items',
    'plan_revisions',
    'plan_revision_changes',
    'production_tasks',
    'execution_reports',
    'problems',
    'problem_messages',
    'wip_entries',
    'audit_entries',
    'idempotency_records',
    'app_sequences',
  ];

  @override
  ContractStoreSnapshot loadOrSeed(ContractStoreSnapshot seedSnapshot) {
    final database = _openDatabase();
    try {
      _runMigrations(database);
      if (_isEmpty(database)) {
        _saveSnapshot(database, seedSnapshot);
        return seedSnapshot;
      }
      return _loadSnapshot(database);
    } finally {
      database.dispose();
    }
  }

  @override
  void save(ContractStoreSnapshot snapshot) {
    final database = _openDatabase();
    try {
      _runMigrations(database);
      _saveSnapshot(database, snapshot);
    } finally {
      database.dispose();
    }
  }

  Database _openDatabase() {
    if (_databasePath != ':memory:') {
      final file = File(_databasePath);
      file.parent.createSync(recursive: true);
    }
    final database = sqlite3.open(_databasePath);
    database.execute('PRAGMA foreign_keys = OFF');
    return database;
  }

  void _runMigrations(Database database) {
    final packageRoot = _resolvePackageRoot();
    final migrationFile = File(
      p.join(
        packageRoot,
        'lib',
        'src',
        'persistence',
        'migrations',
        '001_initial.sql',
      ),
    );
    final sql = migrationFile.readAsStringSync();
    final tableExists = database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'schema_migrations'",
    );
    if (tableExists.isEmpty) {
      database.execute(sql);
      database.execute(
        'INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)',
        ['001_initial', DateTime.now().toUtc().toIso8601String()],
      );
      return;
    }
    final applied = database.select(
      'SELECT version FROM schema_migrations WHERE version = ?',
      ['001_initial'],
    );
    if (applied.isEmpty) {
      database.execute(sql);
      database.execute(
        'INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)',
        ['001_initial', DateTime.now().toUtc().toIso8601String()],
      );
    }
  }

  String _resolvePackageRoot() {
    var current = Directory(_packageRoot ?? Directory.current.path).absolute;
    while (true) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      final migration = File(
        p.join(
          current.path,
          'lib',
          'src',
          'persistence',
          'migrations',
          '001_initial.sql',
        ),
      );
      if (pubspec.existsSync() && migration.existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError(
          'Unable to locate backend package root for SQLite migrations.',
        );
      }
      current = parent;
    }
  }

  bool _isEmpty(Database database) {
    final rows = database.select('SELECT COUNT(*) AS count FROM machines');
    return (rows.single['count'] as int) == 0;
  }

  void _saveSnapshot(Database database, ContractStoreSnapshot snapshot) {
    database.execute('BEGIN IMMEDIATE');
    try {
      for (final table in _tableResetOrder) {
        database.execute('DELETE FROM $table');
      }
      _insertCatalogItems(database, snapshot.catalogItems);
      _insertMachines(database, snapshot.machines);
      _insertVersions(database, snapshot.versions);
      _insertStructureOccurrences(database, snapshot.structureOccurrences);
      _insertOperationOccurrences(database, snapshot.operationOccurrences);
      _insertPlans(database, snapshot.plans);
      _insertTasks(database, snapshot.tasks);
      _insertReports(database, snapshot.reportsByTask);
      _insertProblems(database, snapshot.problems);
      _insertProblemMessages(database, snapshot.problemMessagesByProblem);
      _insertWipEntries(database, snapshot.wipEntries);
      _insertAuditEntries(database, snapshot.auditEntries);
      _insertIdempotencyRecords(database, snapshot.idempotencyRecords);
      _insertSequences(database, snapshot);
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  ContractStoreSnapshot _loadSnapshot(Database database) {
    final catalogItems = database
        .select('SELECT * FROM catalog_items ORDER BY id')
        .map(_catalogItemFromRow)
        .toList(growable: false);
    final machines = database
        .select('SELECT * FROM machines ORDER BY id')
        .map(_machineFromRow)
        .toList(growable: false);
    final versions = database
        .select('SELECT * FROM machine_versions ORDER BY created_at, id')
        .map(_machineVersionFromRow)
        .toList(growable: false);
    final structureOccurrences = database
        .select('SELECT * FROM structure_occurrences ORDER BY id')
        .map(_structureOccurrenceFromRow)
        .toList(growable: false);
    final operationOccurrences = database
        .select('SELECT * FROM operation_occurrences ORDER BY id')
        .map(_operationOccurrenceFromRow)
        .toList(growable: false);
    final plans = _loadPlans(database);
    final tasks = database
        .select('SELECT * FROM production_tasks ORDER BY id')
        .map(_taskFromRow)
        .toList(growable: false);
    final reportsByTask = <String, List<ExecutionReport>>{};
    for (final row in database.select(
      'SELECT * FROM execution_reports ORDER BY reported_at, id',
    )) {
      final report = _executionReportFromRow(row);
      reportsByTask.update(
        report.taskId,
        (items) => [...items, report],
        ifAbsent: () => [report],
      );
    }
    final problems = database
        .select('SELECT * FROM problems ORDER BY created_at, id')
        .map(_problemFromRow)
        .toList(growable: false);
    final problemMessagesByProblem = <String, List<ProblemMessage>>{};
    for (final row in database.select(
      'SELECT * FROM problem_messages ORDER BY created_at, id',
    )) {
      final message = _problemMessageFromRow(row);
      problemMessagesByProblem.update(
        message.problemId,
        (items) => [...items, message],
        ifAbsent: () => [message],
      );
    }
    final wipEntries = database
        .select('SELECT * FROM wip_entries ORDER BY id')
        .map(_wipEntryFromRow)
        .toList(growable: false);
    final auditEntries = database
        .select('SELECT * FROM audit_entries ORDER BY changed_at, id')
        .map(_auditEntryFromRow)
        .toList(growable: false);
    final idempotencyRecords = database
        .select('SELECT * FROM idempotency_records ORDER BY request_id')
        .map(_idempotencyRecordFromRow)
        .toList(growable: false);
    final sequences = {
      for (final row in database.select('SELECT * FROM app_sequences'))
        row['name'] as String: row['value'] as int,
    };

    return ContractStoreSnapshot(
      catalogItems: catalogItems,
      machines: machines,
      versions: versions,
      structureOccurrences: structureOccurrences,
      operationOccurrences: operationOccurrences,
      plans: plans,
      tasks: tasks,
      reportsByTask: reportsByTask.map(
        (key, value) => MapEntry(key, List.unmodifiable(value)),
      ),
      problems: problems,
      problemMessagesByProblem: problemMessagesByProblem.map(
        (key, value) => MapEntry(key, List.unmodifiable(value)),
      ),
      wipEntries: wipEntries,
      auditEntries: auditEntries,
      idempotencyRecords: idempotencyRecords,
      machineSequence: sequences['machine'] ?? 0,
      versionSequence: sequences['version'] ?? 0,
      structureSequence: sequences['structure'] ?? 0,
      operationSequence: sequences['operation'] ?? 0,
      planSequence: sequences['plan'] ?? 0,
      planItemSequence: sequences['plan_item'] ?? 0,
      taskSequence: sequences['task'] ?? 0,
      reportSequence: sequences['report'] ?? 0,
      problemSequence: sequences['problem'] ?? 0,
      problemMessageSequence: sequences['problem_message'] ?? 0,
      auditSequence: sequences['audit'] ?? 0,
    );
  }

  List<Plan> _loadPlans(Database database) {
    final itemsByPlan = <String, List<PlanItem>>{};
    for (final row in database.select('SELECT * FROM plan_items ORDER BY id')) {
      final planId = row['plan_id'] as String;
      final item = PlanItem(
        id: row['id'] as String,
        source: PlanItemSource(
          machineId: row['machine_id'] as String,
          versionId: row['version_id'] as String,
          structureOccurrenceId: row['structure_occurrence_id'] as String,
          catalogItemId: row['catalog_item_id'] as String,
        ),
        requestedQuantity: (row['requested_quantity'] as num).toDouble(),
        hasRecordedExecution: (row['has_recorded_execution'] as int) == 1,
      );
      itemsByPlan.update(planId, (items) => [...items, item], ifAbsent: () => [item]);
    }

    final changesByRevision = <String, List<PlanFieldChange>>{};
    for (final row in database.select(
      'SELECT * FROM plan_revision_changes ORDER BY revision_id, id',
    )) {
      final revisionId = row['revision_id'] as String;
      final change = PlanFieldChange(
        targetId: row['target_id'] as String,
        field: row['field'] as String,
        beforeValue: row['before_value'] as String,
        afterValue: row['after_value'] as String,
      );
      changesByRevision.update(
        revisionId,
        (items) => [...items, change],
        ifAbsent: () => [change],
      );
    }

    final revisionsByPlan = <String, List<PlanRevision>>{};
    for (final row in database.select(
      'SELECT * FROM plan_revisions ORDER BY plan_id, revision_number',
    )) {
      final revision = PlanRevision(
        id: row['id'] as String,
        planId: row['plan_id'] as String,
        revisionNumber: row['revision_number'] as int,
        changedBy: row['changed_by'] as String,
        changedAt: DateTime.parse(row['changed_at'] as String),
        changes: List.unmodifiable(
          changesByRevision[row['id'] as String] ?? const [],
        ),
      );
      revisionsByPlan.update(
        revision.planId,
        (items) => [...items, revision],
        ifAbsent: () => [revision],
      );
    }

    return database
        .select('SELECT * FROM plans ORDER BY created_at, id')
        .map(
          (row) => Plan(
            id: row['id'] as String,
            machineId: row['machine_id'] as String,
            versionId: row['version_id'] as String,
            title: row['title'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            status: _planStatusFromName(row['status'] as String),
            items: List.unmodifiable(itemsByPlan[row['id'] as String] ?? const []),
            revisions: List.unmodifiable(
              revisionsByPlan[row['id'] as String] ?? const [],
            ),
          ),
        )
        .toList(growable: false);
  }

  void _insertCatalogItems(Database db, List<CatalogItem> items) {
    _insertAll(
      db,
      'INSERT INTO catalog_items(id, code, name, kind, description, is_active) VALUES(?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.code,
          item.name,
          item.kind.name,
          item.description,
          item.isActive ? 1 : 0,
        ],
      ),
    );
  }

  void _insertMachines(Database db, List<Machine> items) {
    _insertAll(
      db,
      'INSERT INTO machines(id, code, name, active_version_id) VALUES(?, ?, ?, ?)',
      items.map((item) => [item.id, item.code, item.name, item.activeVersionId]),
    );
  }

  void _insertVersions(Database db, List<MachineVersion> items) {
    _insertAll(
      db,
      'INSERT INTO machine_versions(id, machine_id, label, created_at, status) VALUES(?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.machineId,
          item.label,
          item.createdAt.toIso8601String(),
          item.status.name,
        ],
      ),
    );
  }

  void _insertStructureOccurrences(Database db, List<StructureOccurrence> items) {
    _insertAll(
      db,
      'INSERT INTO structure_occurrences(id, version_id, catalog_item_id, path_key, display_name, quantity_per_machine, parent_occurrence_id, workshop, inherited_workshop, source_position_number, source_owner_name) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.versionId,
          item.catalogItemId,
          item.pathKey,
          item.displayName,
          item.quantityPerMachine,
          item.parentOccurrenceId,
          item.workshop,
          item.inheritedWorkshop ? 1 : 0,
          item.sourcePositionNumber,
          item.sourceOwnerName,
        ],
      ),
    );
  }

  void _insertOperationOccurrences(Database db, List<OperationOccurrence> items) {
    _insertAll(
      db,
      'INSERT INTO operation_occurrences(id, version_id, structure_occurrence_id, name, quantity_per_machine, workshop, inherited_workshop, source_position_number, source_quantity) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.versionId,
          item.structureOccurrenceId,
          item.name,
          item.quantityPerMachine,
          item.workshop,
          item.inheritedWorkshop ? 1 : 0,
          item.sourcePositionNumber,
          item.sourceQuantity,
        ],
      ),
    );
  }

  void _insertPlans(Database db, List<Plan> plans) {
    _insertAll(
      db,
      'INSERT INTO plans(id, machine_id, version_id, title, created_at, status) VALUES(?, ?, ?, ?, ?, ?)',
      plans.map(
        (plan) => [
          plan.id,
          plan.machineId,
          plan.versionId,
          plan.title,
          plan.createdAt.toIso8601String(),
          plan.status.name,
        ],
      ),
    );
    final planItemRows = <List<Object?>>[];
    final revisionRows = <List<Object?>>[];
    final changeRows = <List<Object?>>[];
    var changeSequence = 0;
    for (final plan in plans) {
      for (final item in plan.items) {
        planItemRows.add([
          item.id,
          plan.id,
          item.source.machineId,
          item.source.versionId,
          item.source.structureOccurrenceId,
          item.source.catalogItemId,
          item.requestedQuantity,
          item.hasRecordedExecution ? 1 : 0,
        ]);
      }
      for (final revision in plan.revisions) {
        revisionRows.add([
          revision.id,
          revision.planId,
          revision.revisionNumber,
          revision.changedBy,
          revision.changedAt.toIso8601String(),
        ]);
        for (final change in revision.changes) {
          changeSequence += 1;
          changeRows.add([
            'plan-revision-change-$changeSequence',
            revision.id,
            change.targetId,
            change.field,
            change.beforeValue,
            change.afterValue,
          ]);
        }
      }
    }
    _insertAll(
      db,
      'INSERT INTO plan_items(id, plan_id, machine_id, version_id, structure_occurrence_id, catalog_item_id, requested_quantity, has_recorded_execution) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
      planItemRows,
    );
    _insertAll(
      db,
      'INSERT INTO plan_revisions(id, plan_id, revision_number, changed_by, changed_at) VALUES(?, ?, ?, ?, ?)',
      revisionRows,
    );
    _insertAll(
      db,
      'INSERT INTO plan_revision_changes(id, revision_id, target_id, field, before_value, after_value) VALUES(?, ?, ?, ?, ?, ?)',
      changeRows,
    );
  }

  void _insertTasks(Database db, List<ProductionTask> items) {
    _insertAll(
      db,
      'INSERT INTO production_tasks(id, plan_item_id, operation_occurrence_id, required_quantity, assignee_id, status) VALUES(?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.planItemId,
          item.operationOccurrenceId,
          item.requiredQuantity,
          item.assigneeId,
          item.status.name,
        ],
      ),
    );
  }

  void _insertReports(Database db, Map<String, List<ExecutionReport>> reportsByTask) {
    _insertAll(
      db,
      'INSERT INTO execution_reports(id, task_id, reported_by, reported_at, reported_quantity, outcome, reason, accepted_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
      reportsByTask.values.expand(
        (items) => items.map(
          (item) => [
            item.id,
            item.taskId,
            item.reportedBy,
            item.reportedAt.toIso8601String(),
            item.reportedQuantity,
            item.outcome.name,
            item.reason,
            item.acceptedAt?.toIso8601String(),
          ],
        ),
      ),
    );
  }

  void _insertProblems(Database db, List<Problem> items) {
    _insertAll(
      db,
      'INSERT INTO problems(id, machine_id, task_id, title, type, created_at, status) VALUES(?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.machineId,
          item.taskId,
          item.title,
          item.type.name,
          item.createdAt.toIso8601String(),
          item.status.name,
        ],
      ),
    );
  }

  void _insertProblemMessages(
    Database db,
    Map<String, List<ProblemMessage>> messagesByProblem,
  ) {
    _insertAll(
      db,
      'INSERT INTO problem_messages(id, problem_id, author_id, message, created_at) VALUES(?, ?, ?, ?, ?)',
      messagesByProblem.values.expand(
        (items) => items.map(
          (item) => [
            item.id,
            item.problemId,
            item.authorId,
            item.message,
            item.createdAt.toIso8601String(),
          ],
        ),
      ),
    );
  }

  void _insertWipEntries(Database db, List<WipEntry> items) {
    _insertAll(
      db,
      'INSERT INTO wip_entries(id, machine_id, version_id, structure_occurrence_id, operation_occurrence_id, balance_quantity, task_id, source_report_id, source_outcome, status) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.machineId,
          item.versionId,
          item.structureOccurrenceId,
          item.operationOccurrenceId,
          item.balanceQuantity,
          item.taskId,
          item.sourceReportId,
          item.sourceOutcome?.name,
          item.status.name,
        ],
      ),
    );
  }

  void _insertAuditEntries(Database db, List<AuditEntry> items) {
    _insertAll(
      db,
      'INSERT INTO audit_entries(id, entity_type, entity_id, action, changed_by, changed_at, field, before_value, after_value) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.id,
          item.entityType,
          item.entityId,
          item.action.name,
          item.changedBy,
          item.changedAt.toIso8601String(),
          item.field,
          item.beforeValue,
          item.afterValue,
        ],
      ),
    );
  }

  void _insertIdempotencyRecords(Database db, List<IdempotencyRecord> items) {
    _insertAll(
      db,
      'INSERT INTO idempotency_records(request_id, category, signature, resource_id, secondary_resource_id, status, generated_count) VALUES(?, ?, ?, ?, ?, ?, ?)',
      items.map(
        (item) => [
          item.requestId,
          item.category,
          item.signature,
          item.resourceId,
          item.secondaryResourceId,
          item.status,
          item.generatedCount,
        ],
      ),
    );
  }

  void _insertSequences(Database db, ContractStoreSnapshot snapshot) {
    _insertAll(
      db,
      'INSERT INTO app_sequences(name, value) VALUES(?, ?)',
      {
        'machine': snapshot.machineSequence,
        'version': snapshot.versionSequence,
        'structure': snapshot.structureSequence,
        'operation': snapshot.operationSequence,
        'plan': snapshot.planSequence,
        'plan_item': snapshot.planItemSequence,
        'task': snapshot.taskSequence,
        'report': snapshot.reportSequence,
        'problem': snapshot.problemSequence,
        'problem_message': snapshot.problemMessageSequence,
        'audit': snapshot.auditSequence,
      }.entries.map((entry) => [entry.key, entry.value]),
    );
  }

  void _insertAll(
    Database database,
    String sql,
    Iterable<List<Object?>> rows,
  ) {
    final statement = database.prepare(sql);
    try {
      for (final row in rows) {
        statement.execute(row);
      }
    } finally {
      statement.dispose();
    }
  }

  CatalogItem _catalogItemFromRow(Row row) => CatalogItem(
    id: row['id'] as String,
    code: row['code'] as String,
    name: row['name'] as String,
    kind: _catalogItemKindFromName(row['kind'] as String),
    description: row['description'] as String?,
    isActive: (row['is_active'] as int) == 1,
  );

  Machine _machineFromRow(Row row) => Machine(
    id: row['id'] as String,
    code: row['code'] as String,
    name: row['name'] as String,
    activeVersionId: row['active_version_id'] as String?,
  );

  MachineVersion _machineVersionFromRow(Row row) => MachineVersion(
    id: row['id'] as String,
    machineId: row['machine_id'] as String,
    label: row['label'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    status: _machineVersionStatusFromName(row['status'] as String),
  );

  StructureOccurrence _structureOccurrenceFromRow(Row row) => StructureOccurrence(
    id: row['id'] as String,
    versionId: row['version_id'] as String,
    catalogItemId: row['catalog_item_id'] as String,
    pathKey: row['path_key'] as String,
    displayName: row['display_name'] as String,
    quantityPerMachine: (row['quantity_per_machine'] as num).toDouble(),
    parentOccurrenceId: row['parent_occurrence_id'] as String?,
    workshop: row['workshop'] as String?,
    inheritedWorkshop: (row['inherited_workshop'] as int) == 1,
    sourcePositionNumber: row['source_position_number'] as String?,
    sourceOwnerName: row['source_owner_name'] as String?,
  );

  OperationOccurrence _operationOccurrenceFromRow(Row row) => OperationOccurrence(
    id: row['id'] as String,
    versionId: row['version_id'] as String,
    structureOccurrenceId: row['structure_occurrence_id'] as String,
    name: row['name'] as String,
    quantityPerMachine: (row['quantity_per_machine'] as num).toDouble(),
    workshop: row['workshop'] as String?,
    inheritedWorkshop: (row['inherited_workshop'] as int) == 1,
    sourcePositionNumber: row['source_position_number'] as String?,
    sourceQuantity: (row['source_quantity'] as num?)?.toDouble(),
  );

  ProductionTask _taskFromRow(Row row) => ProductionTask(
    id: row['id'] as String,
    planItemId: row['plan_item_id'] as String,
    operationOccurrenceId: row['operation_occurrence_id'] as String,
    requiredQuantity: (row['required_quantity'] as num).toDouble(),
    assigneeId: row['assignee_id'] as String?,
    status: _taskStatusFromName(row['status'] as String),
  );

  ExecutionReport _executionReportFromRow(Row row) => ExecutionReport(
    id: row['id'] as String,
    taskId: row['task_id'] as String,
    reportedBy: row['reported_by'] as String,
    reportedAt: DateTime.parse(row['reported_at'] as String),
    reportedQuantity: (row['reported_quantity'] as num).toDouble(),
    outcome: _executionReportOutcomeFromName(row['outcome'] as String),
    reason: row['reason'] as String?,
    acceptedAt: (row['accepted_at'] as String?) == null
        ? null
        : DateTime.parse(row['accepted_at'] as String),
  );

  Problem _problemFromRow(Row row) => Problem(
    id: row['id'] as String,
    machineId: row['machine_id'] as String,
    taskId: row['task_id'] as String?,
    title: row['title'] as String?,
    type: _problemTypeFromName(row['type'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
    status: _problemStatusFromName(row['status'] as String),
  );

  ProblemMessage _problemMessageFromRow(Row row) => ProblemMessage(
    id: row['id'] as String,
    problemId: row['problem_id'] as String,
    authorId: row['author_id'] as String,
    message: row['message'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  WipEntry _wipEntryFromRow(Row row) => WipEntry(
    id: row['id'] as String,
    machineId: row['machine_id'] as String,
    versionId: row['version_id'] as String,
    structureOccurrenceId: row['structure_occurrence_id'] as String,
    operationOccurrenceId: row['operation_occurrence_id'] as String,
    balanceQuantity: (row['balance_quantity'] as num).toDouble(),
    taskId: row['task_id'] as String?,
    sourceReportId: row['source_report_id'] as String?,
    sourceOutcome: (row['source_outcome'] as String?) == null
        ? null
        : _executionReportOutcomeFromName(row['source_outcome'] as String),
    status: _wipEntryStatusFromName(row['status'] as String),
  );

  AuditEntry _auditEntryFromRow(Row row) => AuditEntry(
    id: row['id'] as String,
    entityType: row['entity_type'] as String,
    entityId: row['entity_id'] as String,
    action: _auditActionFromName(row['action'] as String),
    changedBy: row['changed_by'] as String,
    changedAt: DateTime.parse(row['changed_at'] as String),
    field: row['field'] as String?,
    beforeValue: row['before_value'] as String?,
    afterValue: row['after_value'] as String?,
  );

  IdempotencyRecord _idempotencyRecordFromRow(Row row) => IdempotencyRecord(
    requestId: row['request_id'] as String,
    category: row['category'] as String,
    signature: row['signature'] as String,
    resourceId: row['resource_id'] as String?,
    secondaryResourceId: row['secondary_resource_id'] as String?,
    status: row['status'] as String?,
    generatedCount: row['generated_count'] as int?,
  );

  CatalogItemKind _catalogItemKindFromName(String value) => switch (value) {
    'machine' => CatalogItemKind.machine,
    'place' => CatalogItemKind.place,
    'assembly' => CatalogItemKind.assembly,
    'detail' => CatalogItemKind.detail,
    'material' => CatalogItemKind.material,
    _ => CatalogItemKind.detail,
  };

  MachineVersionStatus _machineVersionStatusFromName(String value) =>
      switch (value) {
        'draft' => MachineVersionStatus.draft,
        'published' => MachineVersionStatus.published,
        'archived' => MachineVersionStatus.archived,
        _ => MachineVersionStatus.draft,
      };

  PlanStatus _planStatusFromName(String value) => switch (value) {
    'draft' => PlanStatus.draft,
    'released' => PlanStatus.released,
    'completed' => PlanStatus.completed,
    'cancelled' => PlanStatus.cancelled,
    _ => PlanStatus.draft,
  };

  TaskStatus _taskStatusFromName(String value) => switch (value) {
    'pending' => TaskStatus.pending,
    'inProgress' => TaskStatus.inProgress,
    'completed' => TaskStatus.completed,
    'cancelled' => TaskStatus.cancelled,
    _ => TaskStatus.pending,
  };

  ExecutionReportOutcome _executionReportOutcomeFromName(String value) =>
      switch (value) {
        'completed' => ExecutionReportOutcome.completed,
        'partial' => ExecutionReportOutcome.partial,
        'notCompleted' => ExecutionReportOutcome.notCompleted,
        'overrun' => ExecutionReportOutcome.overrun,
        _ => ExecutionReportOutcome.completed,
      };

  ProblemType _problemTypeFromName(String value) => switch (value) {
    'equipment' => ProblemType.equipment,
    'materials' => ProblemType.materials,
    'documentation' => ProblemType.documentation,
    'planningError' => ProblemType.planningError,
    'technologyError' => ProblemType.technologyError,
    'blockedByOtherWorkshop' => ProblemType.blockedByOtherWorkshop,
    _ => ProblemType.other,
  };

  ProblemStatus _problemStatusFromName(String value) => switch (value) {
    'open' => ProblemStatus.open,
    'inProgress' => ProblemStatus.inProgress,
    'closed' => ProblemStatus.closed,
    _ => ProblemStatus.open,
  };

  WipEntryStatus _wipEntryStatusFromName(String value) => switch (value) {
    'open' => WipEntryStatus.open,
    'consumed' => WipEntryStatus.consumed,
    'transferred' => WipEntryStatus.transferred,
    'writtenOff' => WipEntryStatus.writtenOff,
    _ => WipEntryStatus.open,
  };

  AuditAction _auditActionFromName(String value) => switch (value) {
    'created' => AuditAction.created,
    'updated' => AuditAction.updated,
    'statusChanged' => AuditAction.statusChanged,
    _ => AuditAction.archived,
  };
}
