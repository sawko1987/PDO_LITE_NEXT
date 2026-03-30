import 'dart:typed_data';

import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/import/import_flow_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportFlowController', () {
    test('loads machines from backend', () async {
      final client = FakeAdminBackendClient(
        machines: [
          const MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
        ],
      );
      final controller = ImportFlowController(client: client);

      await controller.loadMachines();

      expect(controller.machines, hasLength(1));
      expect(controller.machines.single.code, 'PDO-100');
    });

    test('creates preview session and exposes preview state', () async {
      final client = FakeAdminBackendClient(
        previewSession: buildSession(canConfirm: true),
      );
      final controller = ImportFlowController(client: client);
      controller.setSelectedFile(
        fileName: 'machine.xlsx',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await controller.createPreview();

      expect(controller.session?.sessionId, 'import-session-1');
      expect(controller.session?.preview.fileName, 'machine.xlsx');
      expect(controller.canConfirm, isTrue);
    });

    test('blocked preview keeps confirm disabled', () async {
      final client = FakeAdminBackendClient(
        previewSession: buildSession(canConfirm: false),
      );
      final controller = ImportFlowController(client: client);
      controller.setSelectedFile(
        fileName: 'conflict.mxl',
        bytes: Uint8List.fromList([4, 5, 6]),
      );

      await controller.createPreview();

      expect(controller.session?.preview.canConfirm, isFalse);
      expect(controller.canConfirm, isFalse);
    });

    test('create_version requires target machine selection', () async {
      final client = FakeAdminBackendClient(
        previewSession: buildSession(canConfirm: true),
        machines: [
          const MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
        ],
      );
      final controller = ImportFlowController(client: client);
      controller.setSelectedFile(
        fileName: 'machine.mxl',
        bytes: Uint8List.fromList([7, 8, 9]),
      );

      await controller.loadMachines();
      await controller.createPreview();
      controller.setConfirmMode(ImportConfirmMode.createVersion);

      expect(controller.canConfirm, isFalse);

      controller.selectTargetMachine('machine-1');

      expect(controller.canConfirm, isTrue);
    });

    test('successful confirm refreshes machines and result state', () async {
      final client = FakeAdminBackendClient(
        previewSession: buildSession(canConfirm: true),
        sessionAfterConfirm: buildSession(
          canConfirm: true,
          status: 'confirmed',
          confirmedAt: DateTime.utc(2026, 3, 30, 12),
        ),
        confirmResult: const ConfirmImportResultDto(
          sessionId: 'import-session-1',
          status: 'confirmed',
          mode: 'create_machine',
          machineId: 'machine-2',
          versionId: 'ver-import-2',
          versionLabel: 'import-import-session-1',
        ),
        machines: [
          const MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
        ],
        machinesAfterConfirm: [
          const MachineSummaryDto(
            id: 'machine-1',
            code: 'PDO-100',
            name: 'Machine 100',
            activeVersionId: 'ver-1',
          ),
          const MachineSummaryDto(
            id: 'machine-2',
            code: 'PDO-200',
            name: 'Imported Machine',
            activeVersionId: 'ver-import-2',
          ),
        ],
      );
      final controller = ImportFlowController(client: client);
      controller.setSelectedFile(
        fileName: 'machine.xlsx',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await controller.loadMachines();
      await controller.createPreview();
      await controller.confirmImport();

      expect(controller.confirmResult?.machineId, 'machine-2');
      expect(controller.session?.status, 'confirmed');
      expect(controller.machines, hasLength(2));
    });

    test('backend error is exposed as explicit error state', () async {
      final client = FakeAdminBackendClient(
        listMachinesError: const AdminBackendException(
          message: 'Backend is unavailable.',
        ),
      );
      final controller = ImportFlowController(client: client);

      await controller.loadMachines();

      expect(controller.errorMessage, 'Backend is unavailable.');
    });
  });
}

class FakeAdminBackendClient implements AdminBackendClient {
  FakeAdminBackendClient({
    this.machines = const [],
    this.machinesAfterConfirm,
    this.previewSession,
    this.sessionAfterConfirm,
    this.confirmResult,
    this.listMachinesError,
    this.previewError,
    this.getSessionError,
    this.confirmError,
  });

  final List<MachineSummaryDto> machines;
  final List<MachineSummaryDto>? machinesAfterConfirm;
  final ImportSessionSummaryDto? previewSession;
  final ImportSessionSummaryDto? sessionAfterConfirm;
  final ConfirmImportResultDto? confirmResult;
  final Object? listMachinesError;
  final Object? previewError;
  final Object? getSessionError;
  final Object? confirmError;

  bool _confirmed = false;

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    if (previewError != null) {
      throw previewError!;
    }

    return previewSession ??
        buildSession(canConfirm: true, fileName: request.fileName);
  }

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    if (confirmError != null) {
      throw confirmError!;
    }

    _confirmed = true;
    return confirmResult ??
        const ConfirmImportResultDto(
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
    if (getSessionError != null) {
      throw getSessionError!;
    }

    if (_confirmed && sessionAfterConfirm != null) {
      return sessionAfterConfirm!;
    }

    return previewSession ?? buildSession(canConfirm: true);
  }

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    if (listMachinesError != null) {
      throw listMachinesError!;
    }

    final currentItems = _confirmed && machinesAfterConfirm != null
        ? machinesAfterConfirm!
        : machines;
    return ApiListResponseDto(
      items: currentItems,
      meta: const {'resource': 'machines'},
    );
  }

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    return const ApiListResponseDto(
      items: [],
      meta: {'resource': 'machine_versions'},
    );
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    return const ApiListResponseDto(items: [], meta: {'resource': 'plans'});
  }

  @override
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    return const ApiListResponseDto(
      items: [],
      meta: {'resource': 'planning_source'},
    );
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    throw UnimplementedError();
  }
}

ImportSessionSummaryDto buildSession({
  required bool canConfirm,
  String fileName = 'machine.xlsx',
  String status = 'preview_ready',
  DateTime? confirmedAt,
}) {
  return ImportSessionSummaryDto(
    sessionId: 'import-session-1',
    status: status,
    createdAt: DateTime.utc(2026, 3, 30, 9),
    confirmedAt: confirmedAt,
    preview: ImportPreviewDto(
      fileName: fileName,
      sourceFormat: fileName.endsWith('.mxl') ? 'mxl' : 'excel',
      detectionReason: 'test_fixture',
      rowCount: 3,
      canConfirm: canConfirm,
      catalogItemCount: 2,
      structureOccurrenceCount: 2,
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
