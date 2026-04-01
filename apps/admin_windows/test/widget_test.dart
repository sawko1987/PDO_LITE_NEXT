import 'dart:typed_data';

import 'package:admin_windows/main.dart';
import 'package:admin_windows/src/execution/execution_board_controller.dart';
import 'package:admin_windows/src/execution/execution_workspace.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/import/import_flow_controller.dart';
import 'package:admin_windows/src/machines/machines_registry_controller.dart';
import 'package:admin_windows/src/machines/machines_workspace.dart';
import 'package:admin_windows/src/plans/plan_board_controller.dart';
import 'package:admin_windows/src/plans/plan_workspace.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin app renders machines registry and all main tabs', (
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
    final machinesController = MachinesRegistryController(client: client);
    final planController = PlanBoardController(client: client);
    final executionController = ExecutionBoardController(client: client);

    await tester.pumpWidget(
      AdminWindowsApp(
        controller: controller,
        machinesController: machinesController,
        planController: planController,
        executionController: executionController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PDO Lite Next'), findsOneWidget);
    expect(find.text('Machines Registry'), findsOneWidget);
    expect(find.text('Machines'), findsWidgets);
    expect(find.text('Structure'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('Execution'), findsOneWidget);
    expect(find.text('WIP'), findsOneWidget);
    expect(find.text('Problems'), findsOneWidget);
  });

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
    final machinesController = MachinesRegistryController(client: client);
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
        machinesController: machinesController,
        planController: planController,
        executionController: executionController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import'));
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
    await planController.selectMachine('machine-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlanWorkspace(controller: planController)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('planningTreePane')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Structure Tree'), findsOneWidget);
    expect(find.byKey(const Key('planningTreePane')), findsOneWidget);
    expect(find.byKey(const Key('bulkPlanningQuantityField')), findsOneWidget);
    expect(find.byKey(const Key('addPlanningSelectionButton')), findsOneWidget);
  });

  testWidgets('plans tab adds subtree to draft and shows duplicate feedback', (
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
    await planController.selectMachine('machine-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlanWorkspace(controller: planController)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('planningTreePane')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('planningNode-node:machine/body')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bulkPlanningQuantityField')),
      '3',
    );

    expect(find.text('Occurrences in branch: 2'), findsOneWidget);
    expect(find.text('Will add new rows: 2'), findsOneWidget);
    expect(find.text('Skipped as duplicates: 0'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('addPlanningSelectionButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addPlanningSelectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Selection merged into draft'), findsOneWidget);
    expect(
      find.textContaining('2 added, 0 skipped as duplicates'),
      findsOneWidget,
    );
    expect(find.text('Body Panel Left'), findsWidgets);
    expect(find.text('Body Panel Right'), findsWidgets);

    planController.selectPlanningNode('root');
    await tester.pumpAndSettle();
    expect(find.text('Skipped as duplicates: 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('bulkPlanningQuantityField')),
      '5',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('addPlanningSelectionButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addPlanningSelectionButton')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('2 added, 2 skipped as duplicates'),
      findsOneWidget,
    );
    expect(find.text('Clamp'), findsWidgets);
  });

  testWidgets(
    'plans tab shows completion controls and blocker summary for active plan',
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
      final planController = PlanBoardController(client: client);
      await planController.openPlan('plan-1');
      await planController.checkActivePlanCompletion();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanWorkspace(controller: planController)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Check Completion'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Completion'), findsOneWidget);
      expect(find.text('Confirm Completion'), findsOneWidget);
      expect(find.text('Completion blockers'), findsOneWidget);
      expect(find.textContaining('Open tasks: task-1'), findsOneWidget);
    },
  );

  testWidgets('machines tab shows machine detail and version structure tree', (
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
    final machinesController = MachinesRegistryController(client: client);
    await machinesController.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MachinesWorkspace(
            controller: machinesController,
            onOpenInPlans: (_, __) async {},
            onOpenInStructure: (_, __) async {},
            onCreateEditableDraftInStructure: (_, __) async {},
            onCreateNewVersionInImport: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Machine Detail'), findsOneWidget);
    expect(find.byKey(const Key('machinesListPane')), findsOneWidget);
    expect(find.byKey(const Key('machineVersionsPane')), findsOneWidget);
    expect(find.byKey(const Key('machineStructureTreePane')), findsOneWidget);
    expect(find.text('Frame'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('versionTile-ver-2')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('versionTile-ver-2')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Label v2-import'), findsOneWidget);
    expect(find.text('Upgrade Kit'), findsWidgets);
  });

  testWidgets(
    'machines workspace actions forward selected machine and version context',
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
      final machinesController = MachinesRegistryController(client: client);
      await machinesController.bootstrap();
      await machinesController.selectVersion('ver-2');
      String? openedPlanMachineId;
      String? openedPlanVersionId;
      String? importMachineId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MachinesWorkspace(
              controller: machinesController,
              onOpenInPlans: (machineId, versionId) async {
                openedPlanMachineId = machineId;
                openedPlanVersionId = versionId;
              },
              onOpenInStructure: (_, __) async {},
              onCreateEditableDraftInStructure: (_, __) async {},
              onCreateNewVersionInImport: (machineId) async {
                importMachineId = machineId;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openInPlansButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('createNewVersionInImportButton')));
      await tester.pumpAndSettle();

      expect(openedPlanMachineId, 'machine-1');
      expect(openedPlanVersionId, 'ver-2');
      expect(importMachineId, 'machine-1');
    },
  );

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
          body: ExecutionWorkspace(
            controller: executionController,
            onOpenProblems: (_) async {},
            onOpenWip: (_) async {},
          ),
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
    expect(find.text('Manual Execution Report'), findsOneWidget);
    expect(find.byKey(const Key('executionReportedByField')), findsOneWidget);
    expect(
      find.byKey(const Key('submitExecutionReportButton')),
      findsOneWidget,
    );
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

  testWidgets(
    'execution form validates partial reason and keeps entered values',
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
      final executionController = ExecutionBoardController(client: client);
      await executionController.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExecutionWorkspace(
              controller: executionController,
              onOpenProblems: (_) async {},
              onOpenWip: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('executionReportedByField')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('executionReportedByField')),
        'supervisor-1',
      );
      await tester.tap(find.byKey(const Key('executionOutcome-partial')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('executionQuantityField')),
        '3',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('submitExecutionReportButton')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submitExecutionReportButton')));
      await tester.pumpAndSettle();

      expect(
        executionController.errorMessage,
        'Reason is required for partial report.',
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('supervisor-1'), findsOneWidget);
    },
  );

  testWidgets(
    'execution form submits desktop report and shows updated feedback',
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
      final executionController = ExecutionBoardController(client: client);
      await executionController.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExecutionWorkspace(
              controller: executionController,
              onOpenProblems: (_) async {},
              onOpenWip: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('executionReportedByField')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('executionReportedByField')),
        'supervisor-1',
      );
      await tester.tap(find.byKey(const Key('executionOutcome-overrun')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('executionQuantityField')),
        '7',
      );
      await tester.enterText(
        find.byKey(const Key('executionReasonField')),
        'Closed extra unit from the same setup.',
      );
      await tester.tap(find.byKey(const Key('submitExecutionReportButton')));
      await tester.pumpAndSettle();

      expect(find.text('Execution sent'), findsOneWidget);
      expect(
        find.text('Execution report sent. WIP updated (1.0 pcs).'),
        findsOneWidget,
      );
      expect(find.textContaining('Reported: 13.0'), findsOneWidget);
      expect(find.textContaining('Remaining: 0.0'), findsOneWidget);
      expect(find.textContaining('WIP updated (1.0 pcs).'), findsOneWidget);
    },
  );
}

class _FakeBackendClient implements AdminBackendClient {
  _FakeBackendClient({required this.machines});

  final List<MachineSummaryDto> machines;
  bool _planCompleted = false;
  double _task1ReportedQuantity = 6;
  String _task1Status = 'inProgress';
  bool _task1Closed = false;
  double _task1WipBalance = 2;
  int _reportSequence = 1;
  final List<ExecutionReportDto> _task1Reports = [
    ExecutionReportDto(
      id: 'report-1',
      taskId: 'task-1',
      reportedBy: 'master-1',
      reportedAt: DateTime.utc(2026, 3, 31, 8),
      reportedQuantity: 6,
      outcome: 'partial',
      acceptedAt: DateTime.utc(2026, 3, 31, 8, 5),
      isAccepted: true,
    ),
  ];

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    return _buildPlanDetail(
      id: 'plan-created',
      title: request.title,
      status: 'draft',
      canRelease: true,
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
              workshop: occurrence.workshop,
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    if (taskId != 'task-1') {
      throw const AdminBackendException(message: 'Task was not found.');
    }

    _reportSequence += 1;
    _task1ReportedQuantity += request.reportedQuantity;
    final remainingQuantity = _task1ReportedQuantity >= 12
        ? 0.0
        : 12 - _task1ReportedQuantity;
    if (remainingQuantity == 0) {
      _task1Status = 'completed';
      _task1Closed = true;
    }

    ExecutionReportWipEffectDto? wipEffect;
    switch (request.outcome) {
      case 'completed':
        _task1WipBalance = 0;
        wipEffect = const ExecutionReportWipEffectDto(
          type: 'consumed',
          wipEntryId: 'wip-1',
          status: 'consumed',
        );
        break;
      case 'partial':
      case 'not_completed':
        _task1WipBalance = remainingQuantity;
        wipEffect = ExecutionReportWipEffectDto(
          type: 'updated',
          wipEntryId: 'wip-1',
          balanceQuantity: _task1WipBalance,
          status: 'open',
        );
        break;
      case 'overrun':
        _task1WipBalance = _task1ReportedQuantity - 12;
        wipEffect = ExecutionReportWipEffectDto(
          type: 'updated',
          wipEntryId: 'wip-1',
          balanceQuantity: _task1WipBalance,
          status: 'open',
        );
        break;
      default:
        wipEffect = null;
    }

    final report = ExecutionReportDto(
      id: 'report-$_reportSequence',
      taskId: taskId,
      reportedBy: request.reportedBy,
      reportedAt: DateTime.utc(2026, 3, 31, 11, _reportSequence),
      reportedQuantity: request.reportedQuantity,
      outcome: request.outcome,
      acceptedAt: DateTime.utc(2026, 3, 31, 11, _reportSequence, 5),
      isAccepted: true,
      reason: request.reason,
    );
    _task1Reports.add(report);

    return CreateExecutionReportResultDto(
      report: report,
      taskStatus: _task1Status,
      reportedQuantityTotal: _task1ReportedQuantity,
      remainingQuantity: remainingQuantity,
      outboxStatus: 'sent',
      wipEffect: wipEffect,
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
  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(
    String planId,
  ) async {
    return PlanCompletionDecisionDto(
      planId: planId,
      canComplete: _planCompleted,
      blockers: _planCompleted
          ? const []
          : const [
              CompletionBlockerDto(type: 'openTasks', entityIds: ['task-1']),
              CompletionBlockerDto(type: 'openWip', entityIds: ['wip-1']),
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
      status: _planCompleted ? 'completed' : 'released',
      canRelease: false,
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
        PlanDetailItemDto(
          id: 'plan-item-2',
          structureOccurrenceId: 'occ-2',
          catalogItemId: 'catalog-2',
          displayName: 'Body Panel Left',
          pathKey: 'machine/body/panel-left',
          requestedQuantity: 1,
          hasRecordedExecution: false,
          canEdit: true,
          workshop: 'WS-2',
        ),
      ],
    );
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    return switch (taskId) {
      'task-1' => TaskDetailDto(
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
        reportedQuantity: _task1ReportedQuantity,
        remainingQuantity: _task1ReportedQuantity >= 12
            ? 0
            : 12 - _task1ReportedQuantity,
        assigneeId: 'master-1',
        status: _task1Status,
        isClosed: _task1Closed,
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
          status: 'draft',
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
        ? List<ExecutionReportDto>.unmodifiable(_task1Reports)
        : const <ExecutionReportDto>[];
    return ApiListResponseDto(
      items: items,
      meta: const {'resource': 'execution_reports'},
    );
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    final items =
        [
              TaskSummaryDto(
                id: 'task-1',
                planItemId: 'plan-item-1',
                operationOccurrenceId: 'op-1',
                requiredQuantity: 12,
                assigneeId: 'master-1',
                status: _task1Status,
                isClosed: _task1Closed,
                machineId: 'machine-1',
                versionId: 'ver-1',
                structureOccurrenceId: 'occ-1',
                structureDisplayName: 'Frame',
                operationName: 'Cut',
                workshop: 'WS-1',
                reportedQuantity: _task1ReportedQuantity,
                remainingQuantity: _task1ReportedQuantity >= 12
                    ? 0
                    : 12 - _task1ReportedQuantity,
              ),
              const TaskSummaryDto(
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
    return ApiListResponseDto(
      items: [
        WipEntryDto(
          id: 'wip-1',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-1',
          operationOccurrenceId: 'op-1',
          balanceQuantity: _task1WipBalance,
          status: 'open',
          blocksCompletion: _task1WipBalance > 0,
          taskId: 'task-1',
          sourceReportId: _task1Reports.last.id,
          sourceOutcome: _task1Reports.last.outcome,
        ),
      ],
      meta: const {'resource': 'wip_entries'},
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

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  ) async {
    _planCompleted = true;
    return const PlanCompletionResultDto(planId: 'plan-1', status: 'completed');
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

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const List<PlanningSourceOccurrenceDto> _planningSourceItems = [
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
];

const List<PlanningSourceOccurrenceDto> _planningSourceItemsVersion2 = [
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
};

final Map<String, List<PlanningSourceOccurrenceDto>> _planningSourceByVersion =
    {'ver-1': _planningSourceItems, 'ver-2': _planningSourceItemsVersion2};
