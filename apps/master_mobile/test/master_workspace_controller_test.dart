import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/src/master/master_backend_client.dart';
import 'package:master_mobile/src/master/master_outbox_item.dart';
import 'package:master_mobile/src/master/master_outbox_repository.dart';
import 'package:master_mobile/src/master/master_workspace_controller.dart';

void main() {
  group('MasterWorkspaceController', () {
    test('bootstrap loads assigned tasks and first task detail', () async {
      final controller = MasterWorkspaceController(
        client: _FakeMasterBackendClient(),
        outboxRepository: _MemoryOutboxRepository(),
        assigneeId: 'master-1',
      );

      await controller.bootstrap();

      expect(controller.tasks.length, 2);
      expect(controller.selectedTask?.id, 'task-1');
      expect(controller.reports.length, 1);
      expect(controller.problems.length, 1);
    });

    test(
      'successful submit stores sent outbox item and refreshes progress',
      () async {
        final controller = MasterWorkspaceController(
          client: _FakeMasterBackendClient(),
          outboxRepository: _MemoryOutboxRepository(),
          assigneeId: 'master-1',
        );

        await controller.bootstrap();
        await controller.submitExecutionReport(
          taskId: 'task-1',
          reportedQuantity: 3,
          outcome: 'partial',
          reason: 'Need rework on remaining pieces.',
        );

        expect(controller.outboxItems.first.status, MasterOutboxStatus.sent);
        expect(
          controller.outboxItems.first.operationType,
          MasterOutboxOperationType.executionReport,
        );
        expect(controller.outboxItems.first.reportOutcome, 'partial');
        expect(controller.selectedTask?.reportedQuantity, 9);
        expect(controller.selectedTask?.remainingQuantity, 3);
        expect(
          controller.reportFeedbackMessage,
          'Обновлена запись НЗП (3.0 pcs).',
        );
      },
    );

    test('failed submit keeps outbox item for retry', () async {
      final client = _FakeMasterBackendClient()..failNextSubmit = true;
      final controller = MasterWorkspaceController(
        client: client,
        outboxRepository: _MemoryOutboxRepository(),
        assigneeId: 'master-1',
      );

      await controller.bootstrap();
      await controller.submitExecutionReport(
        taskId: 'task-1',
        reportedQuantity: 2,
        outcome: 'partial',
        reason: 'Paused before finishing batch.',
      );

      expect(controller.outboxItems.first.status, MasterOutboxStatus.failed);

      await controller.retryOutboxItem(controller.outboxItems.first.localId);

      expect(controller.outboxItems.first.status, MasterOutboxStatus.sent);
      expect(controller.selectedTask?.reportedQuantity, 8);
    });

    test(
      'search filters visible tasks by operation and structure context',
      () async {
        final controller = MasterWorkspaceController(
          client: _FakeMasterBackendClient(),
          outboxRepository: _MemoryOutboxRepository(),
          assigneeId: 'master-1',
        );

        await controller.bootstrap();
        controller.setSearchQuery('body');

        expect(controller.visibleTasks.map((task) => task.id), ['task-2']);

        controller.setSearchQuery('WS-1');

        expect(controller.visibleTasks.map((task) => task.id), ['task-1']);
      },
    );

    test(
      'search is trimmed and can be cleared back to full active list',
      () async {
        final controller = MasterWorkspaceController(
          client: _FakeMasterBackendClient(),
          outboxRepository: _MemoryOutboxRepository(),
          assigneeId: 'master-1',
        );

        await controller.bootstrap();
        controller.setSearchQuery('  weld  ');

        expect(controller.visibleTasks.map((task) => task.id), ['task-2']);

        controller.setSearchQuery('');

        expect(controller.visibleTasks.length, 2);
      },
    );

    test(
      'create problem refreshes task problems and stores sent outbox item',
      () async {
        final controller = MasterWorkspaceController(
          client: _FakeMasterBackendClient(),
          outboxRepository: _MemoryOutboxRepository(),
          assigneeId: 'master-1',
        );

        await controller.bootstrap();
        await controller.createProblem(
          taskId: 'task-1',
          type: 'materials',
          title: 'Need blanks',
          description: 'Material kit was not delivered.',
        );

        expect(controller.problems.length, 2);
        expect(
          controller.problems.any((problem) => problem.title == 'Need blanks'),
          isTrue,
        );
        expect(
          controller.outboxItems.first.operationType,
          MasterOutboxOperationType.problemCreate,
        );
        expect(controller.outboxItems.first.status, MasterOutboxStatus.sent);
      },
    );

    test(
      'problem message and close transition update selected problem',
      () async {
        final controller = MasterWorkspaceController(
          client: _FakeMasterBackendClient(),
          outboxRepository: _MemoryOutboxRepository(),
          assigneeId: 'master-1',
        );

        await controller.bootstrap();
        await controller.selectProblem('problem-1');
        await controller.addProblemMessage(
          problemId: 'problem-1',
          message: 'Technician is on the way.',
        );
        await controller.transitionProblem(
          problemId: 'problem-1',
          toStatus: 'closed',
        );

        expect(controller.selectedProblem?.messages.length, 2);
        expect(
          controller.selectedProblem?.messages.last.message,
          'Technician is on the way.',
        );
        expect(controller.selectedProblem?.status, 'closed');
        expect(controller.selectedProblem?.isOpen, isFalse);
        expect(
          controller.outboxItems.first.operationType,
          MasterOutboxOperationType.problemTransition,
        );
        expect(
          controller.outboxItems[1].operationType,
          MasterOutboxOperationType.problemMessage,
        );
      },
    );
  });
}

class _FakeMasterBackendClient implements MasterBackendClient {
  bool failNextSubmit = false;
  String? authToken;

  final Map<String, TaskDetailDto> _tasks = {
    'task-1': const TaskDetailDto(
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
    ),
    'task-2': const TaskDetailDto(
      id: 'task-2',
      planItemId: 'plan-item-2',
      operationOccurrenceId: 'op-2',
      machineId: 'machine-1',
      versionId: 'ver-2026-03',
      structureOccurrenceId: 'occ-2',
      structureDisplayName: 'Body Panel',
      operationName: 'Weld',
      workshop: 'WS-2',
      requiredQuantity: 4,
      reportedQuantity: 0,
      remainingQuantity: 4,
      assigneeId: 'master-1',
      status: 'pending',
      isClosed: false,
    ),
  };

  final Map<String, List<ExecutionReportDto>> _reports = {
    'task-1': [
      ExecutionReportDto(
        id: 'report-1',
        taskId: 'task-1',
        reportedBy: 'master-1',
        reportedAt: DateTime.utc(2026, 3, 31, 9),
        reportedQuantity: 6,
        outcome: 'partial',
        acceptedAt: DateTime.utc(2026, 3, 31, 9, 5),
        isAccepted: true,
      ),
    ],
    'task-2': const [],
  };

  final Map<String, ProblemDetailDto> _problems = {
    'problem-1': ProblemDetailDto(
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
    ),
  };

  int _problemSequence = 2;
  int _problemMessageSequence = 2;

  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) async {
    final problem = _problems[problemId]!;
    if (!problem.isOpen) {
      throw const MasterBackendException(message: 'Problem is closed.');
    }
    final nextMessage = ProblemMessageDto(
      id: 'problem-message-${_problemMessageSequence++}',
      problemId: problemId,
      authorId: request.authorId,
      message: request.message,
      createdAt: DateTime.utc(2026, 3, 31, 11),
    );
    final updated = ProblemDetailDto(
      id: problem.id,
      machineId: problem.machineId,
      type: problem.type,
      taskId: problem.taskId,
      title: problem.title,
      status: problem.status,
      isOpen: problem.isOpen,
      createdAt: problem.createdAt,
      messages: [...problem.messages, nextMessage],
    );
    _problems[problemId] = updated;
    return updated;
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    if (failNextSubmit) {
      failNextSubmit = false;
      throw const MasterBackendException(message: 'Backend is unavailable.');
    }

    final task = _tasks[taskId]!;
    final reportedTotal = task.reportedQuantity + request.reportedQuantity;
    final remaining = reportedTotal >= task.requiredQuantity
        ? 0.0
        : task.requiredQuantity - reportedTotal;
    final nextStatus = remaining == 0 ? 'completed' : 'inProgress';
    final report = ExecutionReportDto(
      id: 'report-${_reports[taskId]!.length + 1}',
      taskId: taskId,
      reportedBy: request.reportedBy,
      reportedAt: DateTime.utc(2026, 3, 31, 10),
      reportedQuantity: request.reportedQuantity,
      outcome: request.outcome,
      reason: request.reason,
      acceptedAt: DateTime.utc(2026, 3, 31, 10, 1),
      isAccepted: true,
    );
    _reports[taskId] = [..._reports[taskId]!, report];
    _tasks[taskId] = TaskDetailDto(
      id: task.id,
      planItemId: task.planItemId,
      operationOccurrenceId: task.operationOccurrenceId,
      machineId: task.machineId,
      versionId: task.versionId,
      structureOccurrenceId: task.structureOccurrenceId,
      structureDisplayName: task.structureDisplayName,
      operationName: task.operationName,
      workshop: task.workshop,
      requiredQuantity: task.requiredQuantity,
      reportedQuantity: reportedTotal,
      remainingQuantity: remaining,
      assigneeId: task.assigneeId,
      status: nextStatus,
      isClosed: remaining == 0,
    );
    return CreateExecutionReportResultDto(
      report: report,
      taskStatus: nextStatus,
      reportedQuantityTotal: reportedTotal,
      remainingQuantity: remaining,
      outboxStatus: 'sent',
      wipEffect: request.outcome == 'completed'
          ? const ExecutionReportWipEffectDto(type: 'consumed')
          : ExecutionReportWipEffectDto(
              type: 'updated',
              wipEntryId: 'wip-1',
              balanceQuantity: remaining,
              status: 'open',
            ),
    );
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) async {
    final createdAt = DateTime.utc(2026, 3, 31, 10, _problemSequence);
    final problemId = 'problem-${_problemSequence++}';
    final detail = ProblemDetailDto(
      id: problemId,
      machineId: _tasks[taskId]!.machineId,
      type: request.type,
      taskId: taskId,
      title: request.title,
      status: 'open',
      isOpen: true,
      createdAt: createdAt,
      messages: [
        ProblemMessageDto(
          id: 'problem-message-${_problemMessageSequence++}',
          problemId: problemId,
          authorId: request.createdBy,
          message: request.description,
          createdAt: createdAt,
        ),
      ],
    );
    _problems[problemId] = detail;
    return detail;
  }

  @override
  void dispose() {}

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async =>
      _problems[problemId]!;

  @override
  Future<TaskDetailDto> getTask(String taskId) async => _tasks[taskId]!;

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    final items = _problems.values
        .where((problem) => taskId == null || problem.taskId == taskId)
        .where((problem) => status == null || problem.status == status)
        .map(
          (problem) => ProblemSummaryDto(
            id: problem.id,
            machineId: problem.machineId,
            type: problem.type,
            taskId: problem.taskId,
            title: problem.title,
            status: problem.status,
            isOpen: problem.isOpen,
            createdAt: problem.createdAt,
            messageCount: problem.messages.length,
          ),
        )
        .toList(growable: false);
    return ApiListResponseDto(
      items: items,
      meta: const {'resource': 'problems'},
    );
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listReports(
    String taskId,
  ) async {
    return ApiListResponseDto(
      items: _reports[taskId] ?? const [],
      meta: const {'resource': 'execution_reports'},
    );
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({
    String? assigneeId,
    String? status,
  }) async {
    final items = _tasks.values
        .map(
          (task) => TaskSummaryDto(
            id: task.id,
            planItemId: task.planItemId,
            operationOccurrenceId: task.operationOccurrenceId,
            requiredQuantity: task.requiredQuantity,
            assigneeId: task.assigneeId,
            status: task.status,
            isClosed: task.isClosed,
            machineId: task.machineId,
            versionId: task.versionId,
            structureOccurrenceId: task.structureOccurrenceId,
            structureDisplayName: task.structureDisplayName,
            operationName: task.operationName,
            workshop: task.workshop,
            reportedQuantity: task.reportedQuantity,
            remainingQuantity: task.remainingQuantity,
          ),
        )
        .toList(growable: false);
    return ApiListResponseDto(items: items, meta: const {'resource': 'tasks'});
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    authToken = 'token-${request.login}';
    return LoginResponseDto(
      token: authToken!,
      userId: request.login,
      role: 'master',
      displayName: 'Master ${request.login}',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
    );
  }

  @override
  Future<void> logout() async {
    authToken = null;
  }

  @override
  void setAuthToken(String? token) {
    authToken = token;
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) async {
    final problem = _problems[problemId]!;
    final updated = ProblemDetailDto(
      id: problem.id,
      machineId: problem.machineId,
      type: problem.type,
      taskId: problem.taskId,
      title: problem.title,
      status: request.toStatus,
      isOpen: request.toStatus != 'closed',
      createdAt: problem.createdAt,
      messages: problem.messages,
    );
    _problems[problemId] = updated;
    return updated;
  }
}

class _MemoryOutboxRepository implements MasterOutboxRepository {
  List<MasterOutboxItem> _items = const [];

  @override
  Future<List<MasterOutboxItem>> loadItems() async => _items;

  @override
  Future<void> saveItems(List<MasterOutboxItem> items) async {
    _items = List<MasterOutboxItem>.from(items);
  }
}
