import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/main.dart';
import 'package:master_mobile/src/master/master_backend_client.dart';
import 'package:master_mobile/src/master/master_outbox_item.dart';
import 'package:master_mobile/src/master/master_outbox_repository.dart';
import 'package:master_mobile/src/master/master_workspace_controller.dart';

void main() {
  testWidgets('master app renders task detail problems and outbox sections', (
    tester,
  ) async {
    final controller = MasterWorkspaceController(
      client: _WidgetFakeBackendClient(),
      outboxRepository: _WidgetMemoryOutboxRepository(),
    );

    await tester.pumpWidget(MasterMobileApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Assigned Task List'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Task Detail'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Task Detail'), findsOneWidget);
    expect(find.text('Problems'), findsOneWidget);
    expect(find.text('Coolant leak'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Offline Outbox'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Offline Outbox'), findsOneWidget);
  });
}

class _WidgetFakeBackendClient implements MasterBackendClient {
  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) async {
    return _problemDetail;
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    return CreateExecutionReportResultDto(
      report: ExecutionReportDto(
        id: 'report-2',
        taskId: taskId,
        reportedBy: request.reportedBy,
        reportedAt: DateTime.utc(2026, 3, 31, 10),
        reportedQuantity: request.reportedQuantity,
        outcome: request.outcome,
        acceptedAt: DateTime.utc(2026, 3, 31, 10, 1),
        isAccepted: true,
      ),
      taskStatus: 'completed',
      reportedQuantityTotal: 12,
      remainingQuantity: 0,
      outboxStatus: 'sent',
      wipEffect: const ExecutionReportWipEffectDto(type: 'consumed'),
    );
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) async {
    return _problemDetail;
  }

  @override
  void dispose() {}

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async => _problemDetail;

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    return const TaskDetailDto(
      id: 'task-1',
      planItemId: 'plan-item-1',
      operationOccurrenceId: 'op-1',
      machineId: 'machine-1',
      versionId: 'ver-2026-03',
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
    );
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    return ApiListResponseDto(
      items: [
        ProblemSummaryDto(
          id: 'problem-1',
          machineId: 'machine-1',
          type: 'equipment',
          taskId: 'task-1',
          title: 'Coolant leak',
          status: 'open',
          isOpen: true,
          createdAt: DateTime.utc(2026, 3, 31, 8, 30),
          messageCount: 1,
        ),
      ],
      meta: const {'resource': 'problems'},
    );
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listReports(
    String taskId,
  ) async {
    return ApiListResponseDto(
      items: [
        ExecutionReportDto(
          id: 'report-1',
          taskId: taskId,
          reportedBy: 'master-1',
          reportedAt: DateTime.utc(2026, 3, 31, 9),
          reportedQuantity: 6,
          outcome: 'partial',
          acceptedAt: DateTime.utc(2026, 3, 31, 9, 5),
          isAccepted: true,
        ),
      ],
      meta: const {'resource': 'execution_reports'},
    );
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({
    String? assigneeId,
    String? status,
  }) async {
    return const ApiListResponseDto(
      items: [
        TaskSummaryDto(
          id: 'task-1',
          planItemId: 'plan-item-1',
          operationOccurrenceId: 'op-1',
          requiredQuantity: 12,
          assigneeId: 'master-1',
          status: 'inProgress',
          isClosed: false,
        ),
      ],
      meta: {'resource': 'tasks'},
    );
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) async {
    return _problemDetail;
  }

  ProblemDetailDto get _problemDetail => ProblemDetailDto(
    id: 'problem-1',
    machineId: 'machine-1',
    type: 'equipment',
    taskId: 'task-1',
    title: 'Coolant leak',
    status: 'open',
    isOpen: true,
    createdAt: DateTime.utc(2026, 3, 31, 8, 30),
    messages: [
      ProblemMessageDto(
        id: 'problem-message-1',
        problemId: 'problem-1',
        authorId: 'master-1',
        message: 'Coolant is leaking near spindle.',
        createdAt: DateTime.utc(2026, 3, 31, 8, 31),
      ),
    ],
  );
}

class _WidgetMemoryOutboxRepository implements MasterOutboxRepository {
  @override
  Future<List<MasterOutboxItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<MasterOutboxItem> items) async {}
}
