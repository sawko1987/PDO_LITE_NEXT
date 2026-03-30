import 'dart:typed_data';

import 'package:admin_windows/main.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/import/import_flow_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'admin app renders import workspace instead of static dashboard',
    (tester) async {
      final controller = ImportFlowController(
        client: _FakeBackendClient(
          machines: const [
            MachineSummaryDto(
              id: 'machine-1',
              code: 'PDO-100',
              name: 'Machine 100',
              activeVersionId: 'ver-1',
            ),
          ],
        ),
      );

      await tester.pumpWidget(AdminWindowsApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('PDO Lite Next'), findsOneWidget);
      expect(find.text('Import Workspace'), findsOneWidget);
      expect(find.text('Planning Board'), findsNothing);
      expect(find.textContaining('machines loaded'), findsOneWidget);
    },
  );

  testWidgets('conflicts and warnings are shown and confirm stays disabled', (
    tester,
  ) async {
    final controller = ImportFlowController(
      client: _FakeBackendClient(
        machines: const [
          MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
        ],
      ),
    );
    controller.setSelectedFile(
      fileName: 'conflict.mxl',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    await controller.createPreview();

    await tester.pumpWidget(AdminWindowsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('duplicate_position_number'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.text('duplicate_position_number'), findsOneWidget);
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
}
