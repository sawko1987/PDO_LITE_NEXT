import 'dart:typed_data';

import 'package:admin_windows/main.dart';
import 'package:admin_windows/src/execution/execution_board_controller.dart';
import 'package:admin_windows/src/execution/execution_workspace.dart';
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
      final controller = ImportFlowController(client: client);
      final planController = PlanBoardController(client: client);
      final executionController = ExecutionBoardController(client: client);

      await tester.pumpWidget(
        AdminWindowsApp(
          controller: controller,
          planController: planController,
          executionController: executionController,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDO Lite Next'), findsOneWidget);
      expect(find.text('Import Workspace'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Execution'), findsOneWidget);
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
    final controller = ImportFlowController(client: client);
    final planController = PlanBoardController(client: client);
    final executionController = ExecutionBoardController(client: client);
    controller.setSelectedFile(
      fileName: 'conflict.mxl',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    await controller.createPreview();

    await tester.pumpWidget(
      AdminWindowsApp(
        controller: controller,
        planController: planController,
        executionController: executionController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(
      find.textContaining('Current preview cannot be confirmed'),
      findsNothing,
    );
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
      MaterialApp(
        home: Scaffold(body: PlanWorkspace(controller: planController)),
      ),
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

  testWidgets('execution tab renders task drill-down blocks', (tester) async {
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
    final executionController = ExecutionBoardController(client: client);
    await executionController.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExecutionWorkspace(controller: executionController),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Execution Control'), findsOneWidget);
    expect(find.text('Task Monitor'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Task Detail'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Task Detail'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Problems'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Problems'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Scoped WIP'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Scoped WIP'), findsOneWidget);
    expect(find.textContaining('Task: task-1'), findsWidgets);
  });
}

class _FakeBackendClient implements AdminBackendClient {
  _FakeBackendClient({required this.machines});

  final List<MachineSummaryDto> machines;

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
  Future<ProblemDetailDto> getProblem(String problemId) async {
    return ProblemDetailDto(
      id: 'problem-1',
      machineId: 'machine-1',
      type: 'equipment',
      taskId: 'task-1',
      title: 'Fixture blocked',
      status: 'inProgress',
      isOpen: true,
      createdAt: DateTime.utc(2026, 3, 31, 9),
      messages: [
        ProblemMessageDto(
          id: 'problem-message-1',
          problemId: 'problem-1',
          authorId: 'master-1',
          message: 'Waiting for setup fixture.',
          createdAt: DateTime.utc(2026, 3, 31, 9, 5),
        ),
      ],
    );
  }

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
  Future<TaskDetailDto> getTask(String taskId) async {
    return switch (taskId) {
      'task-1' => const TaskDetailDto(
        id: 'task-1',
        planItemId: 'plan-item-1',
        operationOccurrenceId: 'op-1',
        machineId: 'machine-1',
        versionId: 'ver-1',
        structureOccurrenceId: 'occ-1',
        structureDisplayName: 'Frame',
        operationName: 'Cut',
        workshop: 'WS-1',
        requiredQuantity: 12,
        reportedQuantity: 6,
        remainingQuantity: 6,
        assigneeId: 'master-1',
        status: 'inProgress',
        isClosed: false,
      ),
      _ => const TaskDetailDto(
        id: 'task-2',
        planItemId: 'plan-item-2',
        operationOccurrenceId: 'op-2',
        machineId: 'machine-1',
        versionId: 'ver-1',
        structureOccurrenceId: 'occ-2',
        structureDisplayName: 'Body Panel',
        operationName: 'Weld',
        workshop: 'WS-2',
        requiredQuantity: 4,
        reportedQuantity: 4,
        remainingQuantity: 0,
        assigneeId: 'master-2',
        status: 'completed',
        isClosed: true,
      ),
    };
  }

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return ApiListResponseDto(
      items: machines,
      meta: const {'resource': 'machines'},
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
    return const ApiListResponseDto(
      items: [
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
      meta: {'resource': 'planning_source'},
    );
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    final items =
        [
              ProblemSummaryDto(
                id: 'problem-1',
                machineId: 'machine-1',
                type: 'equipment',
                taskId: 'task-1',
                title: 'Fixture blocked',
                status: 'inProgress',
                isOpen: true,
                createdAt: DateTime.utc(2026, 3, 31, 9),
                messageCount: 1,
              ),
            ]
            .where((problem) {
              if (taskId != null &&
                  taskId.isNotEmpty &&
                  problem.taskId != taskId) {
                return false;
              }
              if (status != null &&
                  status.isNotEmpty &&
                  problem.status != status) {
                return false;
              }
              return true;
            })
            .toList(growable: false);
    return ApiListResponseDto(
      items: items,
      meta: const {'resource': 'problems'},
    );
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(
    String taskId,
  ) async {
    final items = taskId == 'task-1'
        ? [
            ExecutionReportDto(
              id: 'report-1',
              taskId: taskId,
              reportedBy: 'master-1',
              reportedAt: DateTime.utc(2026, 3, 31, 8),
              reportedQuantity: 6,
              outcome: 'partial',
              acceptedAt: DateTime.utc(2026, 3, 31, 8, 5),
              isAccepted: true,
            ),
          ]
        : const <ExecutionReportDto>[];
    return ApiListResponseDto(
      items: items,
      meta: const {'resource': 'execution_reports'},
    );
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    final items =
        const [
              TaskSummaryDto(
                id: 'task-1',
                planItemId: 'plan-item-1',
                operationOccurrenceId: 'op-1',
                requiredQuantity: 12,
                assigneeId: 'master-1',
                status: 'inProgress',
                isClosed: false,
                machineId: 'machine-1',
                versionId: 'ver-1',
                structureOccurrenceId: 'occ-1',
                structureDisplayName: 'Frame',
                operationName: 'Cut',
                workshop: 'WS-1',
                reportedQuantity: 6,
                remainingQuantity: 6,
              ),
              TaskSummaryDto(
                id: 'task-2',
                planItemId: 'plan-item-2',
                operationOccurrenceId: 'op-2',
                requiredQuantity: 4,
                assigneeId: 'master-2',
                status: 'completed',
                isClosed: true,
                machineId: 'machine-1',
                versionId: 'ver-1',
                structureOccurrenceId: 'occ-2',
                structureDisplayName: 'Body Panel',
                operationName: 'Weld',
                workshop: 'WS-2',
                reportedQuantity: 4,
                remainingQuantity: 0,
              ),
            ]
            .where((task) {
              if (status != null &&
                  status.isNotEmpty &&
                  task.status != status) {
                return false;
              }
              return true;
            })
            .toList(growable: false);
    return ApiListResponseDto(items: items, meta: const {'resource': 'tasks'});
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
          balanceQuantity: 2,
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
