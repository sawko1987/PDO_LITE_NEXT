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
      problems: const [
        Problem(
          id: 'problem-1',
          machineId: 'machine-1',
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
        problems: const [
          Problem(
            id: 'problem-1',
            machineId: 'machine-1',
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
}
