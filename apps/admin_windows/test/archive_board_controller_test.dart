import 'package:admin_windows/src/archive/archive_board_controller.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveBoardController', () {
    test('bootstrap loads archive list and openPlan fetches detail', () async {
      final controller = ArchiveBoardController(
        client: _FakeArchiveBackendClient(),
      );

      await controller.bootstrap();

      expect(controller.machines, hasLength(1));
      expect(controller.plans, hasLength(1));
      expect(controller.plans.single.id, 'plan-2');

      await controller.openPlan('plan-2');

      expect(controller.selectedPlan?.id, 'plan-2');
      expect(controller.selectedSummary?.completionPercent, 100);
      expect(controller.errorMessage, isNull);
    });
  });
}

class _FakeArchiveBackendClient implements AdminBackendClient {
  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return const ApiListResponseDto(
      items: [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'Machine 100',
          activeVersionId: 'ver-2026-03',
        ),
      ],
      meta: {'resource': 'machines'},
    );
  }

  @override
  Future<ApiListResponseDto<PlanArchiveItemDto>> listArchivePlans({
    String? machineId,
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    return ApiListResponseDto(
      items: [
        PlanArchiveItemDto(
          id: 'plan-2',
          machineId: 'machine-1',
          machineCode: 'PDO-100',
          versionId: 'ver-2026-03',
          title: 'Completed plan',
          status: status ?? 'completed',
          createdAt: DateTime.utc(2026, 3, 27, 6),
          completedAt: DateTime.utc(2026, 3, 27, 15, 30),
          itemCount: 1,
          totalReported: 5,
          completionPercent: 100,
        ),
      ],
      meta: const {'resource': 'archive_plans'},
    );
  }

  @override
  Future<PlanDetailDto> getArchivePlan(String planId) async {
    return PlanDetailDto(
      id: planId,
      machineId: 'machine-1',
      versionId: 'ver-2026-03',
      title: 'Completed plan',
      createdAt: DateTime.utc(2026, 3, 27, 6),
      status: 'completed',
      canRelease: false,
      itemCount: 1,
      revisionCount: 0,
      items: const [
        PlanDetailItemDto(
          id: 'item-1',
          structureOccurrenceId: 'occ-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          requestedQuantity: 5,
          hasRecordedExecution: true,
          canEdit: true,
          workshop: 'WS-1',
        ),
      ],
      revisions: const [],
      executionSummary: const PlanExecutionSummaryDto(
        planId: 'plan-2',
        totalRequested: 5,
        totalReported: 5,
        completionPercent: 100,
        taskCount: 1,
        closedTaskCount: 1,
        problemCount: 0,
        wipConsumedCount: 0,
      ),
    );
  }

  @override
  Future<PlanExecutionSummaryDto> getArchivePlanExecutionSummary(
    String planId,
  ) async {
    return const PlanExecutionSummaryDto(
      planId: 'plan-2',
      totalRequested: 5,
      totalReported: 5,
      completionPercent: 100,
      taskCount: 1,
      closedTaskCount: 1,
      problemCount: 0,
      wipConsumedCount: 0,
    );
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
