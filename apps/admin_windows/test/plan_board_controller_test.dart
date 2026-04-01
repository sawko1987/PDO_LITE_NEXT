import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/plans/plan_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanBoardController', () {
    test('loads machines and plans during bootstrap', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.bootstrap();

      expect(controller.machines, hasLength(1));
      expect(controller.plans.single.title, 'Seed plan');
      expect(controller.wipEntries.single.id, 'wip-1');
    });

    test('selecting machine loads versions and planning source', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');

      expect(controller.versions, hasLength(2));
      expect(controller.selectedVersionId, 'ver-1');
      expect(controller.planningSource, hasLength(4));
      expect(controller.planningTreeRoot?.label, 'Whole machine: PDO-100');
      expect(controller.selectedPlanningNodeId, 'root');
    });

    test('builds planning tree from flat planning source', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');

      final root = controller.planningTreeRoot;
      expect(root, isNotNull);
      expect(root!.descendantOccurrenceIds, hasLength(4));
      expect(root.children.single.label, 'machine');

      final machineNode = root.children.single;
      final bodyNode = machineNode.children.firstWhere(
        (node) => node.pathKey == 'machine/body',
      );
      expect(bodyNode.descendantOccurrenceIds, hasLength(2));
      expect(
        bodyNode.children
            .where((node) => node.isLeaf)
            .map((node) => node.label)
            .toList(),
        ['Body Panel Left', 'Body Panel Right'],
      );
    });

    test(
      'selecting root adds whole machine to draft with one quantity',
      () async {
        final controller = PlanBoardController(
          client: _FakePlanBackendClient(),
        );

        await controller.loadMachines();
        await controller.selectMachine('machine-1');
        controller.setBulkAddQuantity('2');
        controller.selectPlanningNode('root');

        controller.addSelectedPlanningNodeToDraft();

        expect(controller.draftSelections, hasLength(4));
        expect(
          controller.draftSelections
              .map((selection) => selection.requestedQuantity)
              .toSet(),
          {2.0},
        );
      },
    );

    test('selecting subtree adds only descendant occurrences', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');
      controller.selectPlanningNode('node:machine/body');
      controller.setBulkAddQuantity('3');

      controller.addSelectedPlanningNodeToDraft();

      expect(
        controller.draftSelections
            .map((selection) => selection.occurrence.id)
            .toList(),
        ['occ-2', 'occ-3'],
      );
      expect(controller.lastBulkDraftAddResult?.addedOccurrenceCount, 2);
    });

    test('overlapping subtree adds merge without duplicates', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');
      controller.selectPlanningNode('node:machine/body');
      controller.setBulkAddQuantity('3');
      controller.addSelectedPlanningNodeToDraft();

      controller.selectPlanningNode('root');
      controller.setBulkAddQuantity('5');
      controller.addSelectedPlanningNodeToDraft();

      expect(controller.draftSelections, hasLength(4));
      expect(controller.lastBulkDraftAddResult?.skippedOccurrenceCount, 2);
      expect(
        controller.draftSelections
            .firstWhere((selection) => selection.occurrence.id == 'occ-2')
            .requestedQuantity,
        3,
      );
      expect(
        controller.draftSelections
            .firstWhere((selection) => selection.occurrence.id == 'occ-1')
            .requestedQuantity,
        5,
      );
    });

    test('individual draft quantity can be adjusted after bulk add', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');
      controller.selectPlanningNode('root');
      controller.setBulkAddQuantity('4');
      controller.addSelectedPlanningNodeToDraft();

      controller.updateRequestedQuantity('occ-3', '7');

      expect(
        controller.draftSelections
            .firstWhere((selection) => selection.occurrence.id == 'occ-3')
            .requestedQuantity,
        7,
      );
      expect(
        controller.draftSelections
            .firstWhere((selection) => selection.occurrence.id == 'occ-2')
            .requestedQuantity,
        4,
      );
    });

    test('create draft and release refresh active plan state', () async {
      final controller = PlanBoardController(client: _FakePlanBackendClient());

      await controller.loadMachines();
      await controller.selectMachine('machine-1');
      controller.setPlanTitle('New draft');
      controller.addOccurrenceToDraft(controller.planningSource.first);

      await controller.createPlan();

      expect(controller.activePlan?.title, 'New draft');
      expect(controller.activePlan?.status, 'draft');
      expect(controller.canReleaseActivePlan, isTrue);

      await controller.releaseActivePlan();

      expect(controller.releaseResult?.status, 'released');
      expect(controller.activePlan?.status, 'released');
    });

    test(
      'openMachineVersion preselects machine and version for plans',
      () async {
        final controller = PlanBoardController(
          client: _FakePlanBackendClient(),
        );

        await controller.openMachineVersion(
          machineId: 'machine-1',
          versionId: 'ver-2',
        );

        expect(controller.selectedMachineId, 'machine-1');
        expect(controller.selectedVersionId, 'ver-2');
        expect(controller.planningSource, hasLength(2));
      },
    );

    test(
      'completion check exposes blockers for released active plan',
      () async {
        final controller = PlanBoardController(
          client: _FakePlanBackendClient(
            completionDecision: const PlanCompletionDecisionDto(
              planId: 'plan-2',
              canComplete: false,
              blockers: [
                CompletionBlockerDto(type: 'openTasks', entityIds: ['task-7']),
              ],
            ),
          ),
        );

        await controller.loadMachines();
        await controller.openPlan('plan-2');
        await controller.checkActivePlanCompletion();

        expect(controller.completionDecision?.canComplete, isFalse);
        expect(controller.completionDecision?.blockers.single.entityIds, [
          'task-7',
        ]);
        expect(controller.canConfirmActivePlanCompletion, isFalse);
      },
    );

    test('successful completion refreshes active plan state', () async {
      final controller = PlanBoardController(
        client: _FakePlanBackendClient(
          completionDecision: const PlanCompletionDecisionDto(
            planId: 'plan-2',
            canComplete: true,
            blockers: [],
          ),
        ),
      );

      await controller.loadMachines();
      await controller.openPlan('plan-2');
      await controller.checkActivePlanCompletion();
      await controller.completeActivePlan();

      expect(controller.completionResult?.status, 'completed');
      expect(controller.activePlan?.status, 'completed');
    });
  });
}

class _FakePlanBackendClient implements AdminBackendClient {
  _FakePlanBackendClient({PlanCompletionDecisionDto? completionDecision})
    : _completionDecision =
          completionDecision ??
          const PlanCompletionDecisionDto(
            planId: 'plan-2',
            canComplete: false,
            blockers: [
              CompletionBlockerDto(type: 'openTasks', entityIds: ['task-1']),
              CompletionBlockerDto(
                type: 'openProblems',
                entityIds: ['problem-1'],
              ),
            ],
          );

  bool _released = false;
  bool _completed = false;
  PlanCompletionDecisionDto _completionDecision;

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    return PlanDetailDto(
      id: 'plan-2',
      machineId: request.machineId,
      versionId: request.versionId,
      title: request.title,
      createdAt: DateTime.utc(2026, 3, 30),
      status: 'draft',
      canRelease: true,
      itemCount: request.items.length,
      revisionCount: 0,
      items: request.items
          .map((item) {
            final occurrence = _planningSourceItems.firstWhere(
              (sourceItem) => sourceItem.id == item.structureOccurrenceId,
            );
            return PlanDetailItemDto(
              id: 'item-${item.structureOccurrenceId}',
              structureOccurrenceId: item.structureOccurrenceId,
              catalogItemId: occurrence.catalogItemId,
              displayName: occurrence.displayName,
              pathKey: occurrence.pathKey,
              requestedQuantity: item.requestedQuantity,
              hasRecordedExecution: false,
              canEdit: true,
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ImportSessionSummaryDto> getImportSession(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(
    String planId,
  ) async {
    return _completionDecision;
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    return PlanDetailDto(
      id: planId,
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: 'New draft',
      createdAt: DateTime.utc(2026, 3, 30),
      status: _completed
          ? 'completed'
          : ((_released || planId == 'plan-2') ? 'released' : 'draft'),
      canRelease: !_released && !_completed && planId != 'plan-2',
      itemCount: 2,
      revisionCount: 0,
      items: const [
        PlanDetailItemDto(
          id: 'item-occ-1',
          structureOccurrenceId: 'occ-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          requestedQuantity: 1,
          hasRecordedExecution: false,
          canEdit: true,
        ),
        PlanDetailItemDto(
          id: 'item-occ-2',
          structureOccurrenceId: 'occ-2',
          catalogItemId: 'catalog-2',
          displayName: 'Body Panel Left',
          pathKey: 'machine/body/panel-left',
          requestedQuantity: 1,
          hasRecordedExecution: false,
          canEdit: true,
        ),
      ],
    );
  }

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return const ApiListResponseDto(
      items: [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'Machine 100',
          activeVersionId: 'ver-1',
        ),
      ],
      meta: {'resource': 'machines'},
    );
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    return ApiListResponseDto(
      items: _versionsByMachine[machineId] ?? const [],
      meta: const {'resource': 'machine_versions'},
    );
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    return ApiListResponseDto(
      items: [
        PlanSummaryDto(
          id: 'plan-1',
          machineId: 'machine-1',
          versionId: 'ver-1',
          title: 'Seed plan',
          createdAt: DateTime.utc(2026, 3, 30),
          status: 'released',
          itemCount: 2,
          revisionCount: 0,
        ),
      ],
      meta: const {'resource': 'plans'},
    );
  }

  @override
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    return ApiListResponseDto(
      items: _planningSourceByVersion[versionId] ?? const [],
      meta: {'resource': 'planning_source'},
    );
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(
    String taskId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<WipEntryDto>> listWipEntries() async {
    return const ApiListResponseDto(
      items: [
        WipEntryDto(
          id: 'wip-1',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-1',
          operationOccurrenceId: 'op-1',
          balanceQuantity: 3,
          status: 'open',
          blocksCompletion: true,
          taskId: 'task-1',
          sourceReportId: 'report-1',
          sourceOutcome: 'partial',
        ),
      ],
      meta: {'resource': 'wip_entries'},
    );
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    _released = true;
    return const PlanReleaseResultDto(
      planId: 'plan-2',
      status: 'released',
      generatedTaskCount: 1,
    );
  }

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  ) async {
    _completed = true;
    _completionDecision = PlanCompletionDecisionDto(
      planId: planId,
      canComplete: true,
      blockers: const [],
    );
    return const PlanCompletionResultDto(planId: 'plan-2', status: 'completed');
  }
}

final Map<String, List<MachineVersionSummaryDto>> _versionsByMachine = {
  'machine-1': [
    MachineVersionSummaryDto(
      id: 'ver-1',
      machineId: 'machine-1',
      label: 'v1',
      createdAt: DateTime.utc(2026, 3, 30),
      status: 'published',
      isImmutable: true,
    ),
    MachineVersionSummaryDto(
      id: 'ver-2',
      machineId: 'machine-1',
      label: 'v2-import',
      createdAt: DateTime.utc(2026, 4, 1),
      status: 'published',
      isImmutable: true,
    ),
  ],
};

final Map<String, List<PlanningSourceOccurrenceDto>> _planningSourceByVersion =
    {'ver-1': _planningSourceItems, 'ver-2': _planningSourceItemsVersion2};

const List<PlanningSourceOccurrenceDto> _planningSourceItems = [
  PlanningSourceOccurrenceDto(
    id: 'occ-1',
    catalogItemId: 'catalog-1',
    displayName: 'Frame',
    pathKey: 'machine/frame',
    quantityPerMachine: 1,
    operationCount: 1,
    workshop: 'WS-1',
  ),
  PlanningSourceOccurrenceDto(
    id: 'occ-2',
    catalogItemId: 'catalog-2',
    displayName: 'Body Panel Left',
    pathKey: 'machine/body/panel-left',
    quantityPerMachine: 1,
    operationCount: 2,
    workshop: 'WS-2',
  ),
  PlanningSourceOccurrenceDto(
    id: 'occ-3',
    catalogItemId: 'catalog-3',
    displayName: 'Body Panel Right',
    pathKey: 'machine/body/panel-right',
    quantityPerMachine: 1,
    operationCount: 2,
    workshop: 'WS-2',
  ),
  PlanningSourceOccurrenceDto(
    id: 'occ-4',
    catalogItemId: 'catalog-4',
    displayName: 'Clamp',
    pathKey: 'machine/tooling/clamp',
    quantityPerMachine: 1,
    operationCount: 1,
    workshop: 'WS-3',
  ),
];

const List<PlanningSourceOccurrenceDto> _planningSourceItemsVersion2 = [
  PlanningSourceOccurrenceDto(
    id: 'occ-5',
    catalogItemId: 'catalog-5',
    displayName: 'Upgrade Kit',
    pathKey: 'machine/upgrade/kit',
    quantityPerMachine: 1,
    operationCount: 3,
    workshop: 'WS-4',
  ),
  PlanningSourceOccurrenceDto(
    id: 'occ-6',
    catalogItemId: 'catalog-6',
    displayName: 'Safety Cover',
    pathKey: 'machine/upgrade/safety-cover',
    quantityPerMachine: 1,
    operationCount: 2,
    workshop: 'WS-4',
  ),
];
