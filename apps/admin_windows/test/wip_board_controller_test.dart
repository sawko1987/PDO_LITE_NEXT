import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/wip/wip_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WipBoardController', () {
    test('filters entries and keeps selected drill-down stable', () async {
      final controller = WipBoardController(client: _FakeWipBackendClient());

      await controller.bootstrap();

      expect(controller.selectedEntry?.id, 'wip-1');
      expect(controller.visibleEntries, hasLength(3));

      controller.setMachineFilter('machine-2');

      expect(controller.visibleEntries.map((entry) => entry.id), ['wip-3']);
      expect(controller.selectedEntry?.id, 'wip-3');

      controller.clearFilters();
      controller.setOperationFilter('Cut');

      expect(controller.visibleEntries.map((entry) => entry.id), ['wip-1']);
    });

    test('openTaskScope narrows list to related task entries', () async {
      final controller = WipBoardController(client: _FakeWipBackendClient());

      await controller.bootstrap();
      controller.openTaskScope('task-2');

      expect(controller.visibleEntries.map((entry) => entry.id), ['wip-2']);
      expect(controller.selectedEntry?.taskId, 'task-2');
    });
  });
}

class _FakeWipBackendClient implements AdminBackendClient {
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
          planId: 'plan-1',
          structureDisplayName: 'Frame',
          operationName: 'Cut',
          workshop: 'WS-1',
        ),
        WipEntryDto(
          id: 'wip-2',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-2',
          operationOccurrenceId: 'op-2',
          balanceQuantity: 1,
          status: 'open',
          blocksCompletion: true,
          taskId: 'task-2',
          planId: 'plan-1',
          structureDisplayName: 'Panel',
          operationName: 'Weld',
          workshop: 'WS-2',
        ),
        WipEntryDto(
          id: 'wip-3',
          machineId: 'machine-2',
          versionId: 'ver-4',
          structureOccurrenceId: 'occ-9',
          operationOccurrenceId: 'op-9',
          balanceQuantity: 0,
          status: 'consumed',
          blocksCompletion: false,
          planId: 'plan-9',
          structureDisplayName: 'Bracket',
          operationName: 'Paint',
          workshop: 'WS-9',
        ),
      ],
      meta: {'resource': 'wip_entries'},
    );
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
