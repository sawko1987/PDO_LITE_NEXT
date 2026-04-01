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
  });
}

class _FakeExecutionBackendClient implements AdminBackendClient {
  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    throw UnimplementedError();
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
              reason: 'Paused after first batch.',
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
          balanceQuantity: 6,
          status: 'open',
          blocksCompletion: true,
          taskId: 'task-1',
          sourceReportId: 'report-1',
          sourceOutcome: 'partial',
        ),
        WipEntryDto(
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
        WipEntryDto(
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
      meta: {'resource': 'wip_entries'},
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
