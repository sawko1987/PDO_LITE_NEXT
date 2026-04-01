import 'package:admin_windows/src/execution/execution_board_controller.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExecutionBoardController', () {
    test(
      'bootstrap loads tasks and wip, then selects first visible task',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(),
        );

        await controller.bootstrap();

        expect(controller.tasks, hasLength(2));
        expect(controller.wipEntries, hasLength(3));
        expect(controller.selectedTask?.id, 'task-1');
        expect(controller.selectedProblem?.id, 'problem-1');
      },
    );

    test(
      'filter changes visible tasks and falls back to first available item',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(),
        );

        await controller.bootstrap();
        await controller.selectTask('task-1');
        await controller.setFilter(ExecutionTaskFilter.completed);

        expect(controller.visibleTasks.map((task) => task.id), ['task-2']);
        expect(controller.selectedTask?.id, 'task-2');
        expect(controller.selectedProblem?.id, 'problem-2');
      },
    );

    test(
      'selectTask loads detail, reports, problems, and first problem thread',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(),
        );

        await controller.bootstrap();
        await controller.selectTask('task-1');

        expect(controller.selectedTask?.structureDisplayName, 'Frame');
        expect(controller.reports.single.id, 'report-1');
        expect(controller.taskProblems.single.title, 'Fixture blocked');
        expect(
          controller.selectedProblem?.messages.single.message,
          'Waiting for setup fixture.',
        );
      },
    );

    test(
      'scopedWipEntries include only linked task or operation entries',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(),
        );

        await controller.bootstrap();

        expect(controller.scopedWipEntries.map((entry) => entry.id), [
          'wip-1',
          'wip-2',
        ]);
      },
    );

    test(
      'submitSelectedTaskReport updates task detail reports and wip feedback',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(),
        );

        await controller.bootstrap();
        controller.setReportAuthor('supervisor-1');
        controller.setReportOutcome('overrun');
        controller.setReportQuantity('7');
        controller.setReportReason('Closed extra unit from the same setup.');

        await controller.submitSelectedTaskReport();

        expect(controller.errorMessage, isNull);
        expect(controller.selectedTask?.status, 'completed');
        expect(controller.selectedTask?.reportedQuantity, 13);
        expect(controller.selectedTask?.remainingQuantity, 0);
        expect(controller.reports, hasLength(2));
        expect(controller.reports.last.outcome, 'overrun');
        expect(controller.scopedWipEntries.first.balanceQuantity, 1);
        expect(
          controller.submissionMessage,
          'Execution report sent. WIP updated (1.0 pcs).',
        );
        expect(controller.reportOutcome, 'completed');
        expect(controller.reportQuantity, isEmpty);
        expect(controller.reportReason, isEmpty);
        expect(controller.reportAuthor, 'supervisor-1');
      },
    );

    test(
      'submitSelectedTaskReport keeps form values on backend error',
      () async {
        final controller = ExecutionBoardController(
          client: _FakeExecutionBackendClient(
            createReportError: const AdminBackendException(
              code: 'invalid_report_reason',
              message: 'Reason is required.',
              statusCode: 422,
            ),
          ),
        );

        await controller.bootstrap();
        controller.setReportAuthor('supervisor-1');
        controller.setReportOutcome('partial');
        controller.setReportQuantity('3');
        controller.setReportReason('Still blocked.');

        await controller.submitSelectedTaskReport();

        expect(controller.errorMessage, 'Reason is required.');
        expect(controller.reportAuthor, 'supervisor-1');
        expect(controller.reportOutcome, 'partial');
        expect(controller.reportQuantity, '3');
        expect(controller.reportReason, 'Still blocked.');
        expect(controller.reports, hasLength(1));
      },
    );
  });
}

class _FakeExecutionBackendClient implements AdminBackendClient {
  _FakeExecutionBackendClient({this.createReportError});

  final Object? createReportError;

  double _task1ReportedQuantity = 6;
  String _task1Status = 'inProgress';
  bool _task1Closed = false;
  double _task1WipBalance = 6;
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
      reason: 'Paused after first batch.',
    ),
  ];

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    if (createReportError != null) {
      throw createReportError!;
    }
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
  Future<ProblemDetailDto> getProblem(String problemId) async {
    return switch (problemId) {
      'problem-1' => ProblemDetailDto(
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
      ),
      'problem-2' => ProblemDetailDto(
        id: 'problem-2',
        machineId: 'machine-1',
        type: 'materials',
        taskId: 'task-2',
        title: 'Delivered late',
        status: 'closed',
        isOpen: false,
        createdAt: DateTime.utc(2026, 3, 31, 10),
        messages: [
          ProblemMessageDto(
            id: 'problem-message-2',
            problemId: 'problem-2',
            authorId: 'master-2',
            message: 'Material reached the line after shift close.',
            createdAt: DateTime.utc(2026, 3, 31, 10, 10),
          ),
        ],
      ),
      _ => throw const AdminBackendException(message: 'Problem was not found.'),
    };
  }

  @override
  Future<ImportSessionSummaryDto> getImportSession(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(
    String planId,
  ) async {
    throw UnimplementedError();
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
      'task-2' => const TaskDetailDto(
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
      _ => throw const AdminBackendException(message: 'Task was not found.'),
    };
  }

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    throw UnimplementedError();
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
              ProblemSummaryDto(
                id: 'problem-2',
                machineId: 'machine-1',
                type: 'materials',
                taskId: 'task-2',
                title: 'Delivered late',
                status: 'closed',
                isOpen: false,
                createdAt: DateTime.utc(2026, 3, 31, 10),
                messageCount: 2,
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
        const WipEntryDto(
          id: 'wip-2',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-3',
          operationOccurrenceId: 'op-1',
          balanceQuantity: 1,
          status: 'open',
          blocksCompletion: true,
          sourceOutcome: 'overrun',
        ),
        const WipEntryDto(
          id: 'wip-3',
          machineId: 'machine-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-2',
          operationOccurrenceId: 'op-2',
          balanceQuantity: 0,
          status: 'consumed',
          blocksCompletion: false,
          taskId: 'task-2',
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
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  ) async {
    throw UnimplementedError();
  }
}
