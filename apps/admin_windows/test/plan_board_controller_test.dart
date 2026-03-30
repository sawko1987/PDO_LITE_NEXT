import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/plans/plan_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanBoardController', () {
    test('loads machines and plans during bootstrap', () async {
      final controller = PlanBoardController(
        client: _FakePlanBackendClient(),
      );

      await controller.bootstrap();

      expect(controller.machines, hasLength(1));
      expect(controller.plans.single.title, 'Seed plan');
    });

    test('selecting machine loads versions and planning source', () async {
      final controller = PlanBoardController(
        client: _FakePlanBackendClient(),
      );

      await controller.loadMachines();
      await controller.selectMachine('machine-1');

      expect(controller.versions, hasLength(1));
      expect(controller.selectedVersionId, 'ver-1');
      expect(controller.planningSource.single.displayName, 'Frame');
    });

    test('create draft and release refresh active plan state', () async {
      final controller = PlanBoardController(
        client: _FakePlanBackendClient(),
      );

      await controller.loadMachines();
      await controller.selectMachine('machine-1');
      controller.setPlanTitle('New draft');
      controller.addOccurrenceToDraft(controller.planningSource.single);

      await controller.createPlan();

      expect(controller.activePlan?.title, 'New draft');
      expect(controller.activePlan?.status, 'draft');
      expect(controller.canReleaseActivePlan, isTrue);

      await controller.releaseActivePlan();

      expect(controller.releaseResult?.status, 'released');
      expect(controller.activePlan?.status, 'released');
    });
  });
}

class _FakePlanBackendClient implements AdminBackendClient {
  bool _released = false;

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
          .map(
            (item) => PlanDetailItemDto(
              id: 'item-${item.structureOccurrenceId}',
              structureOccurrenceId: item.structureOccurrenceId,
              catalogItemId: 'catalog-${item.structureOccurrenceId}',
              displayName: 'Frame',
              pathKey: 'machine/frame',
              requestedQuantity: item.requestedQuantity,
              hasRecordedExecution: false,
              canEdit: true,
            ),
          )
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
  Future<PlanDetailDto> getPlan(String planId) async {
    return PlanDetailDto(
      id: planId,
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: 'New draft',
      createdAt: DateTime.utc(2026, 3, 30),
      status: _released ? 'released' : 'draft',
      canRelease: !_released,
      itemCount: 1,
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
      items: [
        MachineVersionSummaryDto(
          id: 'ver-1',
          machineId: machineId,
          label: 'v1',
          createdAt: DateTime.utc(2026, 3, 30),
          status: 'published',
          isImmutable: true,
        ),
      ],
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
          itemCount: 1,
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
    return const ApiListResponseDto(
      items: [
        PlanningSourceOccurrenceDto(
          id: 'occ-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          quantityPerMachine: 1,
          operationCount: 1,
          workshop: 'WS-1',
        ),
      ],
      meta: {'resource': 'planning_source'},
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
}
