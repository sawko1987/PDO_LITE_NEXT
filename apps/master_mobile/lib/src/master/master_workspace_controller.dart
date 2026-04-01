import 'dart:math';

import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import 'master_backend_client.dart';
import 'master_outbox_item.dart';
import 'master_outbox_repository.dart';

enum MasterTaskFilter { active, completed }

class MasterWorkspaceController extends ChangeNotifier {
  MasterWorkspaceController({
    required MasterBackendClient client,
    required MasterOutboxRepository outboxRepository,
    this.assigneeId = 'master-1',
  }) : _client = client,
       _outboxRepository = outboxRepository;

  final String assigneeId;
  final MasterBackendClient _client;
  final MasterOutboxRepository _outboxRepository;
  final Random _random = Random();

  bool _bootstrapped = false;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _reportFeedbackMessage;
  List<MasterOutboxItem> _outboxItems = const [];
  List<ProblemSummaryDto> _problems = const [];
  List<ExecutionReportDto> _reports = const [];
  ProblemDetailDto? _selectedProblem;
  String? _selectedProblemId;
  TaskDetailDto? _selectedTask;
  String? _selectedTaskId;
  String _searchQuery = '';
  MasterTaskFilter _taskFilter = MasterTaskFilter.active;
  List<TaskSummaryDto> _tasks = const [];

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get reportFeedbackMessage => _reportFeedbackMessage;
  List<MasterOutboxItem> get outboxItems => _outboxItems;
  List<ProblemSummaryDto> get problems => _problems;
  List<ExecutionReportDto> get reports => _reports;
  ProblemDetailDto? get selectedProblem => _selectedProblem;
  TaskDetailDto? get selectedTask => _selectedTask;
  String get searchQuery => _searchQuery;
  MasterTaskFilter get taskFilter => _taskFilter;
  List<TaskSummaryDto> get tasks => _tasks;

  List<TaskSummaryDto> get visibleTasks {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _tasks
        .where((task) {
          final matchesFilter = switch (_taskFilter) {
            MasterTaskFilter.active => !task.isClosed,
            MasterTaskFilter.completed => task.isClosed,
          };
          if (!matchesFilter) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          return _matchesTaskSearch(task, normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    await _runLoading(() async {
      _outboxItems = await _outboxRepository.loadItems();
      await _refreshTasksAndSelection();
    });
  }

  Future<void> createProblem({
    required String taskId,
    required String type,
    required String title,
    required String description,
  }) async {
    final item = MasterOutboxItem(
      localId: _buildLocalId(),
      operationType: MasterOutboxOperationType.problemCreate,
      requestId: _buildRequestId('problem-create'),
      authorId: assigneeId,
      createdAt: DateTime.now().toUtc(),
      status: MasterOutboxStatus.pending,
      taskId: taskId,
      title: title.trim(),
      problemType: type,
      message: description.trim(),
    );
    await _queueAndSendOutboxItem(item);
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> addProblemMessage({
    required String problemId,
    required String message,
  }) async {
    final item = MasterOutboxItem(
      localId: _buildLocalId(),
      operationType: MasterOutboxOperationType.problemMessage,
      requestId: _buildRequestId('problem-message'),
      authorId: assigneeId,
      createdAt: DateTime.now().toUtc(),
      status: MasterOutboxStatus.pending,
      problemId: problemId,
      message: message.trim(),
    );
    await _queueAndSendOutboxItem(item);
  }

  Future<void> transitionProblem({
    required String problemId,
    required String toStatus,
  }) async {
    final item = MasterOutboxItem(
      localId: _buildLocalId(),
      operationType: MasterOutboxOperationType.problemTransition,
      requestId: _buildRequestId('problem-transition'),
      authorId: assigneeId,
      createdAt: DateTime.now().toUtc(),
      status: MasterOutboxStatus.pending,
      problemId: problemId,
      toStatus: toStatus,
    );
    await _queueAndSendOutboxItem(item);
  }

  Future<void> refresh() async {
    await _runLoading(_refreshTasksAndSelection);
  }

  Future<void> retryOutboxItem(String localId) async {
    final index = _outboxItems.indexWhere((item) => item.localId == localId);
    if (index == -1) {
      return;
    }

    _outboxItems = [
      for (var i = 0; i < _outboxItems.length; i++)
        if (i == index)
          _outboxItems[i].copyWith(
            status: MasterOutboxStatus.pending,
            clearLastError: true,
          )
        else
          _outboxItems[i],
    ];
    await _persistOutbox();
    notifyListeners();
    await _sendOutboxItem(localId);
  }

  Future<void> selectProblem(String problemId) async {
    await _runLoading(() async {
      _selectedProblemId = problemId;
      _selectedProblem = await _client.getProblem(problemId);
    });
  }

  Future<void> selectTask(String taskId) async {
    await _runLoading(() async {
      await _loadTask(taskId);
    });
  }

  void setFilter(MasterTaskFilter filter) {
    if (_taskFilter == filter) {
      return;
    }
    _taskFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    final normalizedValue = value.trimLeft();
    if (_searchQuery == normalizedValue) {
      return;
    }
    _searchQuery = normalizedValue;
    notifyListeners();
  }

  Future<void> submitExecutionReport({
    required String taskId,
    required double reportedQuantity,
    required String outcome,
    String? reason,
  }) async {
    final item = MasterOutboxItem(
      localId: _buildLocalId(),
      operationType: MasterOutboxOperationType.executionReport,
      requestId: _buildRequestId('report'),
      authorId: assigneeId,
      createdAt: DateTime.now().toUtc(),
      status: MasterOutboxStatus.pending,
      taskId: taskId,
      reportedQuantity: reportedQuantity,
      reportOutcome: outcome,
      reason: _normalize(reason),
    );
    await _queueAndSendOutboxItem(item);
  }

  String _buildLocalId() =>
      'outbox-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 20)}';

  String _buildRequestId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 20)}';

  Future<void> _loadTask(String taskId) async {
    _selectedTaskId = taskId;
    _selectedTask = await _client.getTask(taskId);
    final reportsResponse = await _client.listReports(taskId);
    _reports = reportsResponse.items;
    await _loadProblemsForTask(taskId);
  }

  Future<void> _loadProblemsForTask(String taskId) async {
    final problemsResponse = await _client.listProblems(taskId: taskId);
    _problems = problemsResponse.items;
    final selectedProblemId = _selectedProblemId;
    if (_problems.any((problem) => problem.id == selectedProblemId)) {
      _selectedProblem = await _client.getProblem(selectedProblemId!);
    } else {
      _selectedProblem = null;
      _selectedProblemId = null;
    }
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _persistOutbox() {
    return _outboxRepository.saveItems(_outboxItems);
  }

  Future<void> _queueAndSendOutboxItem(MasterOutboxItem item) async {
    _outboxItems = [item, ..._outboxItems];
    await _persistOutbox();
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _sendOutboxItem(item.localId);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _refreshTasksAndSelection() async {
    final tasksResponse = await _client.listTasks(assigneeId: assigneeId);
    _tasks = tasksResponse.items;
    if (_tasks.isEmpty) {
      _selectedTaskId = null;
      _selectedTask = null;
      _reports = const [];
      _problems = const [];
      _selectedProblem = null;
      _selectedProblemId = null;
      return;
    }

    final selectedId = _selectedTaskId;
    final taskId = _tasks.any((task) => task.id == selectedId)
        ? selectedId!
        : _tasks.first.id;
    await _loadTask(taskId);
  }

  Future<void> _runLoading(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on MasterBackendException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'Unexpected error: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendOutboxItem(String localId) async {
    final index = _outboxItems.indexWhere((item) => item.localId == localId);
    if (index == -1) {
      return;
    }

    final item = _outboxItems[index];
    try {
      switch (item.operationType) {
        case MasterOutboxOperationType.executionReport:
          final result = await _client.createExecutionReport(
            item.taskId ?? '',
            CreateExecutionReportRequestDto(
              requestId: item.requestId,
              reportedBy: item.authorId,
              reportedQuantity: item.reportedQuantity ?? 0,
              outcome: item.reportOutcome ?? 'completed',
              reason: item.reason,
            ),
          );
          _handleExecutionReportResult(result);
          break;
        case MasterOutboxOperationType.problemCreate:
          await _client.createProblem(
            item.taskId ?? '',
            CreateProblemRequestDto(
              requestId: item.requestId,
              createdBy: item.authorId,
              type: item.problemType ?? 'other',
              title: item.title ?? '',
              description: item.message ?? '',
            ),
          );
          break;
        case MasterOutboxOperationType.problemMessage:
          await _client.addProblemMessage(
            item.problemId ?? '',
            AddProblemMessageRequestDto(
              requestId: item.requestId,
              authorId: item.authorId,
              message: item.message ?? '',
            ),
          );
          break;
        case MasterOutboxOperationType.problemTransition:
          await _client.transitionProblem(
            item.problemId ?? '',
            TransitionProblemRequestDto(
              requestId: item.requestId,
              changedBy: item.authorId,
              toStatus: item.toStatus ?? '',
            ),
          );
          break;
      }
      _outboxItems = [
        for (var i = 0; i < _outboxItems.length; i++)
          if (i == index)
            _outboxItems[i].copyWith(
              status: MasterOutboxStatus.sent,
              clearLastError: true,
            )
          else
            _outboxItems[i],
      ];
      await _persistOutbox();
      await _refreshTasksAndSelection();
    } on MasterBackendException catch (error) {
      _outboxItems = [
        for (var i = 0; i < _outboxItems.length; i++)
          if (i == index)
            _outboxItems[i].copyWith(
              status: MasterOutboxStatus.failed,
              lastError: error.message,
            )
          else
            _outboxItems[i],
      ];
      _errorMessage = error.message;
      await _persistOutbox();
    }
  }

  void _handleExecutionReportResult(CreateExecutionReportResultDto result) {
    _reportFeedbackMessage = _describeWipEffect(result);
  }

  String? _describeWipEffect(CreateExecutionReportResultDto result) {
    final effect = result.wipEffect;
    if (effect == null || effect.type == 'none') {
      return null;
    }
    final balance = effect.balanceQuantity;
    final formattedBalance = balance == null ? '' : ' ($balance pcs)';
    return switch (effect.type) {
      'created' => 'WIP created$formattedBalance.',
      'updated' => 'WIP updated$formattedBalance.',
      'consumed' => 'Existing WIP was consumed.',
      _ => null,
    };
  }

  bool _matchesTaskSearch(TaskSummaryDto task, String query) {
    final haystack = <String>[
      task.id,
      task.machineId,
      task.versionId,
      task.structureOccurrenceId,
      task.structureDisplayName,
      task.operationName,
      task.workshop,
      task.assigneeId ?? '',
      task.status,
    ].map((value) => value.toLowerCase());

    return haystack.any((value) => value.contains(query));
  }
}
