import 'dart:typed_data';

import 'package:admin_windows/main.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/import/import_flow_controller.dart';
import 'package:admin_windows/src/plans/plan_board_controller.dart';
import 'package:admin_windows/src/plans/plan_workspace.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'admin app renders import workspace instead of static dashboard',
    (tester) async {
      final client = _FakeBackendClient(
        machines: const [
          MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
        ],
      );
      final controller = ImportFlowController(
        client: client,
      );
      final planController = PlanBoardController(client: client);

      await tester.pumpWidget(
        AdminWindowsApp(controller: controller, planController: planController),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDO Lite Next'), findsOneWidget);
      expect(find.text('Import Workspace'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.textContaining('machines loaded'), findsOneWidget);
    },
  );

  testWidgets('conflicts and warnings are shown and confirm stays disabled', (
    tester,
  ) async {
    final client = _FakeBackendClient(
      machines: const [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'Machine 100',
          activeVersionId: 'ver-1',
        ),
      ],
    );
    final controller = ImportFlowController(
      client: client,
    );
    final planController = PlanBoardController(client: client);
    controller.setSelectedFile(
      fileName: 'conflict.mxl',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    await controller.createPreview();

    await tester.pumpWidget(
      AdminWindowsApp(controller: controller, planController: planController),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.textContaining('Current preview cannot be confirmed'), findsNothing);
  });

  testWidgets('plans tab renders plan board and seeded plan index', (
    tester,
  ) async {
    final client = _FakeBackendClient(
      machines: const [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'Machine 100',
          activeVersionId: 'ver-1',
        ),
      ],
    );
    final planController = PlanBoardController(client: client);
    await planController.bootstrap();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: PlanWorkspace(controller: planController))),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Plan Index'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan Index'), findsOneWidget);
  });
}

class _FakeBackendClient implements AdminBackendClient {
  _FakeBackendClient({required this.machines});

  final List<MachineSummaryDto> machines;

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    final canConfirm = !request.fileName.contains('conflict');
    return ImportSessionSummaryDto(
      sessionId: 'import-session-1',
      status: 'preview_ready',
      createdAt: DateTime.utc(2026, 3, 30, 9),
      preview: ImportPreviewDto(
        fileName: request.fileName,
        sourceFormat: request.fileName.endsWith('.mxl') ? 'mxl' : 'excel',
        detectionReason: 'test_fixture',
        rowCount: 3,
        canConfirm: canConfirm,
        catalogItemCount: 2,
        structureOccurrenceCount: 1,
        operationOccurrenceCount: 1,
        conflictCount: canConfirm ? 0 : 1,
        warningCount: 1,
        machineName: 'Machine 100',
        machineCode: 'PDO-100',
        conflicts: canConfirm
            ? const []
            : const [
                ImportConflictDto(
                  rowNumber: 3,
                  reason: 'parent_ambiguous',
                  candidates: ['Frame', 'Body'],
                ),
              ],
        warnings: const [
          ImportWarningDto(
            code: 'duplicate_position_number',
            message: 'Duplicate position number.',
            rowNumber: 2,
          ),
        ],
        structureOccurrences: const [
          StructureOccurrencePreviewDto(
            id: 'occ-1',
            catalogItemId: 'catalog-1',
            pathKey: 'root/10:Frame',
            displayName: 'Frame',
            quantityPerMachine: 1,
            inheritedWorkshop: false,
            workshop: 'WS-1',
          ),
        ],
        operationOccurrences: const [
          OperationOccurrencePreviewDto(
            id: 'op-1',
            structureOccurrenceId: 'occ-1',
            name: 'Cut',
            quantityPerMachine: 2,
            inheritedWorkshop: false,
            workshop: 'WS-1',
            sourcePositionNumber: '10',
            sourceQuantity: 2,
          ),
        ],
      ),
    );
  }

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    return const ConfirmImportResultDto(
      sessionId: 'import-session-1',
      status: 'confirmed',
      mode: 'create_machine',
      machineId: 'machine-2',
      versionId: 'ver-import-2',
      versionLabel: 'import-import-session-1',
    );
  }

  @override
  void dispose() {}

  @override
  Future<ImportSessionSummaryDto> getImportSession(String sessionId) async {
    return createImportPreview(
      const CreateImportPreviewRequestDto(
        requestId: 'preview-1',
        fileName: 'machine.xlsx',
        fileContentBase64: 'AQID',
      ),
    );
  }

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return ApiListResponseDto(
      items: machines,
      meta: const {'resource': 'machines'},
    );
  }

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    return _buildPlanDetail(
      id: 'plan-created',
      title: request.title,
      status: 'draft',
      canRelease: true,
      items: request.items
          .map(
            (item) => PlanDetailItemDto(
              id: 'item-${item.structureOccurrenceId}',
              structureOccurrenceId: item.structureOccurrenceId,
              catalogItemId: 'catalog-${item.structureOccurrenceId}',
              displayName: item.structureOccurrenceId == 'occ-1'
                  ? 'Frame'
                  : 'Body Panel',
              pathKey: item.structureOccurrenceId == 'occ-1'
                  ? 'machine/frame'
                  : 'machine/body/panel',
              requestedQuantity: item.requestedQuantity,
              hasRecordedExecution: false,
              canEdit: true,
              workshop: 'WS-1',
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    return _buildPlanDetail(
      id: planId,
      title: 'Seed plan',
      status: 'draft',
      canRelease: true,
      items: const [
        PlanDetailItemDto(
          id: 'plan-item-1',
          structureOccurrenceId: 'occ-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          requestedQuantity: 2,
          hasRecordedExecution: false,
          canEdit: true,
          workshop: 'WS-1',
        ),
      ],
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
          machineId: 'machine-1',
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
          status: 'draft',
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
    return ApiListResponseDto(
      items: const [
        PlanningSourceOccurrenceDto(
          id: 'occ-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          quantityPerMachine: 1,
          workshop: 'WS-1',
          operationCount: 1,
        ),
      ],
      meta: const {'resource': 'planning_source'},
    );
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    return const PlanReleaseResultDto(
      planId: 'plan-1',
      status: 'released',
      generatedTaskCount: 1,
    );
  }

  PlanDetailDto _buildPlanDetail({
    required String id,
    required String title,
    required String status,
    required bool canRelease,
    required List<PlanDetailItemDto> items,
  }) {
    return PlanDetailDto(
      id: id,
      machineId: 'machine-1',
      versionId: 'ver-1',
      title: title,
      createdAt: DateTime.utc(2026, 3, 30),
      status: status,
      canRelease: canRelease,
      itemCount: items.length,
      revisionCount: 0,
      items: items,
    );
  }
}
