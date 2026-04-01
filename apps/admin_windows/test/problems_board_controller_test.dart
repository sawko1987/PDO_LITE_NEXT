import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/problems/problems_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProblemsBoardController', () {
    test('creates problem, adds message, and closes thread', () async {
      final client = _FakeProblemsBackendClient();
      final controller = ProblemsBoardController(client: client);

      await controller.bootstrap();

      expect(controller.selectedProblem?.id, 'problem-1');

      final created = await controller.createProblem(
        taskId: 'task-1',
        type: 'equipment',
        title: 'Fixture blocked',
        description: 'Cannot proceed without replacement.',
      );

      expect(created, isNotNull);
      expect(controller.selectedProblem?.title, 'Fixture blocked');

      final messageResult = await controller.addMessage('Maintenance called.');
      expect(messageResult?.messages.length, 2);
      expect(
        controller.selectedProblem?.messages.last.message,
        'Maintenance called.',
      );

      final closed = await controller.transitionSelectedProblem('closed');
      expect(closed?.status, 'closed');
      expect(controller.selectedProblem?.status, 'closed');
    });

    test(
      'task scope and filters keep visible problem selection in sync',
      () async {
        final controller = ProblemsBoardController(
          client: _FakeProblemsBackendClient(),
        );

        await controller.bootstrap();
        await controller.openTaskScope('task-2');

        expect(controller.visibleProblems.map((item) => item.id), [
          'problem-2',
        ]);
        expect(controller.selectedProblem?.id, 'problem-2');

        await controller.setStatusFilter('closed');

        expect(controller.visibleProblems.map((item) => item.id), [
          'problem-2',
        ]);
        expect(controller.selectedProblem?.status, 'closed');
      },
    );
  });
}

class _FakeProblemsBackendClient implements AdminBackendClient {
  final List<TaskSummaryDto> _tasks = const [
    TaskSummaryDto(
      id: 'task-1',
      planItemId: 'plan-item-1',
      operationOccurrenceId: 'op-1',
      requiredQuantity: 2,
      assigneeId: 'master-1',
      status: 'inProgress',
      isClosed: false,
      machineId: 'machine-1',
      versionId: 'ver-1',
      structureOccurrenceId: 'occ-1',
      structureDisplayName: 'Frame',
      operationName: 'Cut',
      workshop: 'WS-1',
      reportedQuantity: 1,
      remainingQuantity: 1,
    ),
    TaskSummaryDto(
      id: 'task-2',
      planItemId: 'plan-item-2',
      operationOccurrenceId: 'op-2',
      requiredQuantity: 1,
      assigneeId: 'master-2',
      status: 'completed',
      isClosed: true,
      machineId: 'machine-1',
      versionId: 'ver-1',
      structureOccurrenceId: 'occ-2',
      structureDisplayName: 'Panel',
      operationName: 'Weld',
      workshop: 'WS-2',
      reportedQuantity: 1,
      remainingQuantity: 0,
    ),
  ];

  final List<ProblemSummaryDto> _problems = [
    ProblemSummaryDto(
      id: 'problem-1',
      machineId: 'machine-1',
      type: 'materials',
      taskId: 'task-1',
      title: 'Missing blanks',
      status: 'open',
      isOpen: true,
      createdAt: DateTime.utc(2026, 4, 1, 8),
      messageCount: 1,
    ),
    ProblemSummaryDto(
      id: 'problem-2',
      machineId: 'machine-1',
      type: 'equipment',
      taskId: 'task-2',
      title: 'Welding gun replaced',
      status: 'closed',
      isOpen: false,
      createdAt: DateTime.utc(2026, 4, 1, 9),
      messageCount: 1,
    ),
  ];

  final Map<String, ProblemDetailDto> _details = {
    'problem-1': ProblemDetailDto(
      id: 'problem-1',
      machineId: 'machine-1',
      type: 'materials',
      taskId: 'task-1',
      title: 'Missing blanks',
      status: 'open',
      isOpen: true,
      createdAt: DateTime.utc(2026, 4, 1, 8),
      messages: [
        ProblemMessageDto(
          id: 'message-1',
          problemId: 'problem-1',
          authorId: 'master-1',
          message: 'Need material delivery.',
          createdAt: DateTime.utc(2026, 4, 1, 8, 5),
        ),
      ],
    ),
    'problem-2': ProblemDetailDto(
      id: 'problem-2',
      machineId: 'machine-1',
      type: 'equipment',
      taskId: 'task-2',
      title: 'Welding gun replaced',
      status: 'closed',
      isOpen: false,
      createdAt: DateTime.utc(2026, 4, 1, 9),
      messages: [
        ProblemMessageDto(
          id: 'message-2',
          problemId: 'problem-2',
          authorId: 'master-2',
          message: 'Issue resolved.',
          createdAt: DateTime.utc(2026, 4, 1, 9, 15),
        ),
      ],
    ),
  };

  int _problemSequence = 2;
  int _messageSequence = 2;

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    final items = _problems
        .where((problem) {
          if (taskId != null && taskId.isNotEmpty && problem.taskId != taskId) {
            return false;
          }
          if (status != null && status.isNotEmpty && problem.status != status) {
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
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    return ApiListResponseDto(items: _tasks, meta: const {'resource': 'tasks'});
  }

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async {
    return _details[problemId]!;
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) async {
    _problemSequence += 1;
    final task = _tasks.firstWhere((item) => item.id == taskId);
    final problemId = 'problem-$_problemSequence';
    final detail = ProblemDetailDto(
      id: problemId,
      machineId: task.machineId,
      type: request.type,
      taskId: taskId,
      title: request.title,
      status: 'open',
      isOpen: true,
      createdAt: DateTime.utc(2026, 4, 1, 10),
      messages: [
        ProblemMessageDto(
          id: 'message-${++_messageSequence}',
          problemId: problemId,
          authorId: request.createdBy,
          message: request.description,
          createdAt: DateTime.utc(2026, 4, 1, 10, 1),
        ),
      ],
    );
    _details[problemId] = detail;
    _problems.add(
      ProblemSummaryDto(
        id: problemId,
        machineId: task.machineId,
        type: request.type,
        taskId: taskId,
        title: request.title,
        status: 'open',
        isOpen: true,
        createdAt: detail.createdAt,
        messageCount: 1,
      ),
    );
    return detail;
  }

  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) async {
    final detail = _details[problemId]!;
    final updated = ProblemDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      type: detail.type,
      taskId: detail.taskId,
      title: detail.title,
      status: detail.status,
      isOpen: detail.isOpen,
      createdAt: detail.createdAt,
      messages: [
        ...detail.messages,
        ProblemMessageDto(
          id: 'message-${++_messageSequence}',
          problemId: problemId,
          authorId: request.authorId,
          message: request.message,
          createdAt: DateTime.utc(2026, 4, 1, 10, 5),
        ),
      ],
    );
    _details[problemId] = updated;
    final summaryIndex = _problems.indexWhere((item) => item.id == problemId);
    final summary = _problems[summaryIndex];
    _problems[summaryIndex] = ProblemSummaryDto(
      id: summary.id,
      machineId: summary.machineId,
      type: summary.type,
      taskId: summary.taskId,
      title: summary.title,
      status: summary.status,
      isOpen: summary.isOpen,
      createdAt: summary.createdAt,
      messageCount: updated.messages.length,
    );
    return updated;
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) async {
    final detail = _details[problemId]!;
    final updated = ProblemDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      type: detail.type,
      taskId: detail.taskId,
      title: detail.title,
      status: request.toStatus,
      isOpen: request.toStatus != 'closed',
      createdAt: detail.createdAt,
      messages: detail.messages,
    );
    _details[problemId] = updated;
    final summaryIndex = _problems.indexWhere((item) => item.id == problemId);
    final summary = _problems[summaryIndex];
    _problems[summaryIndex] = ProblemSummaryDto(
      id: summary.id,
      machineId: summary.machineId,
      type: summary.type,
      taskId: summary.taskId,
      title: summary.title,
      status: request.toStatus,
      isOpen: request.toStatus != 'closed',
      createdAt: summary.createdAt,
      messageCount: summary.messageCount,
    );
    return updated;
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
