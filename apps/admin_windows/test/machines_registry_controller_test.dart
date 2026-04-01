import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/machines/machines_registry_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MachinesRegistryController', () {
    test(
      'loads machines and selects first machine with active version',
      () async {
        final client = _FakeMachinesBackendClient();
        final controller = MachinesRegistryController(client: client);

        await controller.bootstrap();

        expect(controller.machines, hasLength(2));
        expect(controller.selectedMachineId, 'machine-1');
        expect(controller.selectedVersionId, 'ver-1');
        expect(controller.selectedVersionOccurrenceCount, 4);
        expect(controller.selectedVersionOperationCount, 6);
      },
    );

    test('selecting version loads version planning source and tree', () async {
      final client = _FakeMachinesBackendClient();
      final controller = MachinesRegistryController(client: client);

      await controller.bootstrap();
      await controller.selectVersion('ver-2');

      expect(controller.selectedVersion?.label, 'v2-import');
      expect(controller.selectedVersionOccurrenceCount, 2);
      expect(controller.selectedVersionOperationCount, 5);
      expect(controller.planningTreeRoot?.label, 'Whole machine: PDO-100');
      final machineNode = controller.planningTreeRoot!.children.single;
      final upgradeNode = machineNode.children.firstWhere(
        (node) => node.pathKey == 'machine/upgrade',
      );
      expect(
        upgradeNode.children
            .firstWhere((node) => node.label == 'Upgrade Kit')
            .label,
        'Upgrade Kit',
      );
    });

    test('aggregates reflect active version marker', () async {
      final client = _FakeMachinesBackendClient();
      final controller = MachinesRegistryController(client: client);

      await controller.bootstrap();
      expect(controller.selectedVersionIsActive, isTrue);

      await controller.selectVersion('ver-2');

      expect(controller.selectedVersionIsActive, isFalse);
    });

    test(
      'refresh keeps current machine and version when still available',
      () async {
        final client = _FakeMachinesBackendClient();
        final controller = MachinesRegistryController(client: client);

        await controller.bootstrap();
        await controller.selectMachine('machine-2');
        await controller.selectVersion('ver-3');

        client.machinesState = [
          const MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-2',
          ),
          const MachineSummaryDto(
            id: 'machine-2',
            code: 'PDO-200',
            name: 'Machine 200',
            activeVersionId: 'ver-3',
          ),
        ];

        await controller.loadMachines();

        expect(controller.selectedMachineId, 'machine-2');
        expect(controller.selectedVersionId, 'ver-3');
        expect(controller.selectedVersionOccurrenceCount, 1);
      },
    );
  });
}

class _FakeMachinesBackendClient implements AdminBackendClient {
  List<MachineSummaryDto> machinesState = const [
    MachineSummaryDto(
      id: 'machine-1',
      code: 'PDO-100',
      name: 'Machine 100',
      activeVersionId: 'ver-1',
    ),
    MachineSummaryDto(
      id: 'machine-2',
      code: 'PDO-200',
      name: 'Machine 200',
      activeVersionId: 'ver-3',
    ),
  ];

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
    'machine-2': [
      MachineVersionSummaryDto(
        id: 'ver-3',
        machineId: 'machine-2',
        label: 'v1',
        createdAt: DateTime.utc(2026, 3, 15),
        status: 'published',
        isImmutable: true,
      ),
    ],
  };

  final Map<String, List<PlanningSourceOccurrenceDto>>
  _planningSourceByVersion = {
    'ver-1': const [
      PlanningSourceOccurrenceDto(
        id: 'occ-1',
        catalogItemId: 'catalog-1',
        displayName: 'Frame',
        pathKey: 'machine/frame',
        quantityPerMachine: 1,
        workshop: 'WS-1',
        operationCount: 1,
      ),
      PlanningSourceOccurrenceDto(
        id: 'occ-2',
        catalogItemId: 'catalog-2',
        displayName: 'Body Panel Left',
        pathKey: 'machine/body/panel-left',
        quantityPerMachine: 1,
        workshop: 'WS-2',
        operationCount: 2,
      ),
      PlanningSourceOccurrenceDto(
        id: 'occ-3',
        catalogItemId: 'catalog-3',
        displayName: 'Body Panel Right',
        pathKey: 'machine/body/panel-right',
        quantityPerMachine: 1,
        workshop: 'WS-2',
        operationCount: 2,
      ),
      PlanningSourceOccurrenceDto(
        id: 'occ-4',
        catalogItemId: 'catalog-4',
        displayName: 'Clamp',
        pathKey: 'machine/tooling/clamp',
        quantityPerMachine: 1,
        workshop: 'WS-3',
        operationCount: 1,
      ),
    ],
    'ver-2': const [
      PlanningSourceOccurrenceDto(
        id: 'occ-5',
        catalogItemId: 'catalog-5',
        displayName: 'Upgrade Kit',
        pathKey: 'machine/upgrade/kit',
        quantityPerMachine: 1,
        workshop: 'WS-4',
        operationCount: 3,
      ),
      PlanningSourceOccurrenceDto(
        id: 'occ-6',
        catalogItemId: 'catalog-6',
        displayName: 'Safety Cover',
        pathKey: 'machine/upgrade/safety-cover',
        quantityPerMachine: 1,
        workshop: 'WS-4',
        operationCount: 2,
      ),
    ],
    'ver-3': const [
      PlanningSourceOccurrenceDto(
        id: 'occ-7',
        catalogItemId: 'catalog-7',
        displayName: 'Base',
        pathKey: 'machine/base',
        quantityPerMachine: 1,
        workshop: 'WS-5',
        operationCount: 1,
      ),
    ],
  };

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return ApiListResponseDto(
      items: machinesState,
      meta: const {'resource': 'machines'},
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
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    return ApiListResponseDto(
      items: _planningSourceByVersion[versionId] ?? const [],
      meta: const {'resource': 'planning_source'},
    );
  }

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

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
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(
    String taskId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<WipEntryDto>> listWipEntries() async {
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
