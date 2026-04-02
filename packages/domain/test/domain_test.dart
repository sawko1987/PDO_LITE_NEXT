import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'same catalog item can produce different occurrence keys in one version',
    () {
      const leftDoor = StructureOccurrence(
        id: 'occ-1',
        versionId: 'ver-1',
        catalogItemId: 'cat-42',
        pathKey: 'machine/place-1/node-1/detail-42',
        displayName: 'КИР 03.060',
        quantityPerMachine: 28,
      );

      const rightDoor = StructureOccurrence(
        id: 'occ-2',
        versionId: 'ver-1',
        catalogItemId: 'cat-42',
        pathKey: 'machine/place-3/node-1/detail-42',
        displayName: 'КИР 03.060',
        quantityPerMachine: 4,
      );

      expect(leftDoor.catalogItemId, rightDoor.catalogItemId);
      expect(leftDoor.occurrenceKey, isNot(rightDoor.occurrenceKey));
    },
  );

  test('published machine version becomes immutable', () {
    final version = MachineVersion(
      id: 'ver-9',
      machineId: 'machine-1',
      label: 'v2026.03.28',
      createdAt: DateTime.utc(2026, 3, 28),
      status: MachineVersionStatus.published,
    );

    expect(version.isImmutable, isTrue);
  });

  test(
    'released plan allows editing only for items without execution facts',
    () {
      final plan = Plan(
        id: 'plan-1',
        machineId: 'machine-1',
        versionId: 'ver-1',
        title: 'План на смену',
        createdAt: DateTime.utc(2026, 3, 28),
        status: PlanStatus.released,
        items: const [
          PlanItem(
            id: 'item-open',
            source: PlanItemSource(
              machineId: 'machine-1',
              versionId: 'ver-1',
              structureOccurrenceId: 'occ-1',
              catalogItemId: 'cat-1',
            ),
            requestedQuantity: 10,
          ),
          PlanItem(
            id: 'item-started',
            source: PlanItemSource(
              machineId: 'machine-1',
              versionId: 'ver-1',
              structureOccurrenceId: 'occ-2',
              catalogItemId: 'cat-2',
            ),
            requestedQuantity: 8,
            hasRecordedExecution: true,
          ),
        ],
        revisions: [
          PlanRevision(
            id: 'rev-2',
            planId: 'plan-1',
            revisionNumber: 2,
            changedBy: 'planner-1',
            changedAt: DateTime.utc(2026, 3, 28, 9),
            changes: [
              PlanFieldChange(
                targetId: 'item-open',
                field: 'requestedQuantity',
                beforeValue: '12',
                afterValue: '10',
              ),
            ],
          ),
        ],
      );

      expect(plan.canEditItem(plan.items.first), isTrue);
      expect(plan.canEditItem(plan.items.last), isFalse);
      expect(plan.revisions.single.changes.single.beforeValue, '12');
    },
  );

  test('draft plan can be released only when it has items', () {
    final emptyDraft = Plan(
      id: 'plan-empty',
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: 'Empty draft',
      createdAt: DateTime.utc(2026, 3, 28),
      items: const [],
    );
    final filledDraft = Plan(
      id: 'plan-filled',
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: 'Filled draft',
      createdAt: DateTime.utc(2026, 3, 28),
      items: const [
        PlanItem(
          id: 'item-1',
          source: PlanItemSource(
            machineId: 'machine-1',
            versionId: 'ver-1',
            structureOccurrenceId: 'occ-1',
            catalogItemId: 'cat-1',
          ),
          requestedQuantity: 2,
        ),
      ],
    );

    expect(emptyDraft.canRelease, isFalse);
    expect(filledDraft.canRelease, isTrue);
  });

  test('plan detects duplicate structure occurrences', () {
    final plan = Plan(
      id: 'plan-duplicates',
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: 'Duplicate draft',
      createdAt: DateTime.utc(2026, 3, 28),
      items: const [
        PlanItem(
          id: 'item-1',
          source: PlanItemSource(
            machineId: 'machine-1',
            versionId: 'ver-1',
            structureOccurrenceId: 'occ-1',
            catalogItemId: 'cat-1',
          ),
          requestedQuantity: 2,
        ),
        PlanItem(
          id: 'item-2',
          source: PlanItemSource(
            machineId: 'machine-1',
            versionId: 'ver-1',
            structureOccurrenceId: 'occ-1',
            catalogItemId: 'cat-2',
          ),
          requestedQuantity: 3,
        ),
      ],
    );

    expect(plan.hasDuplicateStructureOccurrences, isTrue);
  });

  test('completion is blocked by open tasks, problems, and wip', () {
    const policy = CompletionPolicy();

    final decision = policy.evaluate(
      tasks: const [
        ProductionTask(
          id: 'task-1',
          planItemId: 'item-1',
          operationOccurrenceId: 'op-1',
          requiredQuantity: 4,
        ),
      ],
      problems: [
        Problem(
          id: 'problem-1',
          machineId: 'machine-1',
          type: ProblemType.equipment,
          createdAt: DateTime.utc(2026, 3, 28, 12),
          status: ProblemStatus.inProgress,
        ),
      ],
      wipEntries: const [
        WipEntry(
          id: 'wip-1',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-1',
          operationOccurrenceId: 'op-1',
          balanceQuantity: 2,
        ),
      ],
    );

    expect(decision.canComplete, isFalse);
    expect(
      decision.blockers.map((blocker) => blocker.type),
      containsAll([
        CompletionBlockerType.openTasks,
        CompletionBlockerType.openProblems,
        CompletionBlockerType.openWip,
      ]),
    );
  });

  test(
    'completion is allowed only when tasks, problems, and wip are closed',
    () {
      const policy = CompletionPolicy();

      final decision = policy.evaluate(
        tasks: const [
          ProductionTask(
            id: 'task-1',
            planItemId: 'item-1',
            operationOccurrenceId: 'op-1',
            requiredQuantity: 4,
            status: TaskStatus.completed,
          ),
        ],
        problems: [
          Problem(
            id: 'problem-1',
            machineId: 'machine-1',
            type: ProblemType.equipment,
            createdAt: DateTime.utc(2026, 3, 28, 12),
            status: ProblemStatus.closed,
          ),
        ],
        wipEntries: const [
          WipEntry(
            id: 'wip-1',
            machineId: 'machine-1',
            versionId: 'ver-1',
            structureOccurrenceId: 'occ-1',
            operationOccurrenceId: 'op-1',
            balanceQuantity: 0,
            status: WipEntryStatus.consumed,
          ),
        ],
      );

      expect(decision.canComplete, isTrue);
      expect(decision.blockers, isEmpty);
    },
  );

  test('problem stays open until status becomes closed', () {
    final openProblem = Problem(
      id: 'problem-open',
      machineId: 'machine-1',
      type: ProblemType.documentation,
      createdAt: DateTime.utc(2026, 4, 1, 8),
      status: ProblemStatus.open,
    );
    final inProgressProblem = Problem(
      id: 'problem-active',
      machineId: 'machine-1',
      type: ProblemType.other,
      createdAt: DateTime.utc(2026, 4, 1, 9),
      status: ProblemStatus.inProgress,
    );
    final closedProblem = Problem(
      id: 'problem-closed',
      machineId: 'machine-1',
      type: ProblemType.other,
      createdAt: DateTime.utc(2026, 4, 1, 10),
      status: ProblemStatus.closed,
    );

    expect(openProblem.isOpen, isTrue);
    expect(inProgressProblem.isOpen, isTrue);
    expect(closedProblem.isOpen, isFalse);
  });

  test('problem message keeps author and timestamp context', () {
    final message = ProblemMessage(
      id: 'message-1',
      problemId: 'problem-1',
      authorId: 'master-1',
      message: 'Need fixture replacement.',
      createdAt: DateTime.utc(2026, 4, 1, 11),
    );

    expect(message.problemId, 'problem-1');
    expect(message.authorId, 'master-1');
    expect(message.message, contains('fixture'));
  });

  test('user role helpers reflect access boundaries', () {
    expect(UserRole.planner.canManageUsers, isTrue);
    expect(UserRole.supervisor.canManageUsers, isFalse);
    expect(UserRole.master.canEditPlan, isFalse);
    expect(UserRole.supervisor.canClosePlan, isTrue);
    expect(UserRole.planner.canClosePlan, isFalse);
    expect(UserRole.supervisor.canViewAudit, isTrue);
  });

  test('auth session expires based on utc timestamp', () {
    final activeSession = AuthSession(
      token: 'token-1',
      userId: 'user-1',
      role: UserRole.planner,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    final expiredSession = AuthSession(
      token: 'token-2',
      userId: 'user-2',
      role: UserRole.master,
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );

    expect(activeSession.isExpired, isFalse);
    expect(expiredSession.isExpired, isTrue);
  });
}
