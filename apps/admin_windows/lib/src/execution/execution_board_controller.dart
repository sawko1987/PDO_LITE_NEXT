import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

enum ExecutionTaskFilter { all, active, completed }

class ExecutionBoardController extends ChangeNotifier {
  ExecutionBoardController({required this.client});

  final AdminBackendClient client;

  final List<TaskSummaryDto> _tasks = [];
  final List<WipEntryDto> _wipEntries = [];
  final List<ProblemSummaryDto> _allProblems = [];
  final List<ExecutionReportDto> _reports = [];
  final List<ProblemSummaryDto> _taskProblems = [];
  String? _selectedTaskId;
  String? _selectedProblemId;
  TaskDetailDto? _selectedTask;
  ProblemDetailDto? _selectedProblem;
  ExecutionTaskFilter _filter = ExecutionTaskFilter.all;
  String _reportAuthor = 'supervisor-1';
  String _reportOutcome = 'completed';
  String _reportQuantity = '';
  String _reportReason = '';
  bool _isLoading = false;
  bool _isTaskLoading = false;
  bool _isReportSubmitting = false;
  String? _errorMessage;
  String? _submissionMessage;
  int _requestSequence = 0;

  List<TaskSummaryDto> get tasks => List.unmodifiable(_tasks);
  List<WipEntryDto> get wipEntries => List.unmodifiable(_wipEntries);
  List<ProblemSummaryDto> get allProblems => List.unmodifiable(_allProblems);
  List<ExecutionReportDto> get reports => List.unmodifiable(_reports);
  List<ProblemSummaryDto> get taskProblems => List.unmodifiable(_taskProblems);
  TaskDetailDto? get selectedTask => _selectedTask;
  ProblemDetailDto? get selectedProblem => _selectedProblem;
  ExecutionTaskFilter get filter => _filter;
  String get reportAuthor => _reportAuthor;
  String get reportOutcome => _reportOutcome;
  String get reportQuantity => _reportQuantity;
  String get reportReason => _reportReason;
  bool get isLoading => _isLoading;
  bool get isTaskLoading => _isTaskLoading;
  bool get isReportSubmitting => _isReportSubmitting;
  bool get isBusy => _isLoading || _isTaskLoading || _isReportSubmitting;
  String? get errorMessage => _errorMessage;
  String? get submissionMessage => _submissionMessage;

  int get activeTaskCount => _tasks.where((task) => !task.isClosed).length;
  int get openProblemCount =>
      _allProblems.where((problem) => problem.isOpen).length;
  int get openWipCount =>
      _wipEntries.where((entry) => entry.blocksCompletion).length;
  bool get canSubmitSelectedTaskReport =>
      !_isReportSubmitting && _selectedTask != null && !_selectedTask!.isClosed;

  List<TaskSummaryDto> get visibleTasks {
    return _tasks
        .where((task) {
          return switch (_filter) {
            ExecutionTaskFilter.all => true,
            ExecutionTaskFilter.active => !task.isClosed,
            ExecutionTaskFilter.completed => task.isClosed,
          };
        })
        .toList(growable: false);
  }

  List<WipEntryDto> get scopedWipEntries {
    final task = _selectedTask;
    if (task == null) {
      return const [];
    }
    return _wipEntries
        .where((entry) {
          if (entry.taskId == task.id) {
            return true;
          }
          return entry.operationOccurrenceId == task.operationOccurrenceId;
        })
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshCollections();
      await _syncSelectionAfterTaskChange();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectTask(String taskId) async {
    if (_selectedTaskId == taskId && _selectedTask != null) {
      return;
    }
    _resetReportDraft();
    _selectedTaskId = taskId;
    await _loadSelectedTask();
  }

  Future<void> selectProblem(String problemId) async {
    _selectedProblemId = problemId;
    _selectedProblem = null;
    _errorMessage = null;
    _submissionMessage = null;
    _isTaskLoading = true;
    notifyListeners();

    try {
      _selectedProblem = await client.getProblem(problemId);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isTaskLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(ExecutionTaskFilter filter) async {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    _errorMessage = null;
    _submissionMessage = null;
    notifyListeners();
    await _syncSelectionAfterTaskChange();
    notifyListeners();
  }

  void setReportAuthor(String value) {
    if (_reportAuthor == value) {
      return;
    }
    _reportAuthor = value;
    _clearMessages();
    notifyListeners();
  }

  void setReportOutcome(String value) {
    if (_reportOutcome == value) {
      return;
    }
    _reportOutcome = value;
    _clearMessages();
    notifyListeners();
  }

  void setReportQuantity(String value) {
    if (_reportQuantity == value) {
      return;
    }
    _reportQuantity = value;
    _clearMessages();
    notifyListeners();
  }

  void setReportReason(String value) {
    if (_reportReason == value) {
      return;
    }
    _reportReason = value;
    _clearMessages();
    notifyListeners();
  }

  Future<void> submitSelectedTaskReport() async {
    final task = _selectedTask;
    if (task == null) {
      _errorMessage = 'Select a task before sending execution report.';
      notifyListeners();
      return;
    }
    if (task.isClosed) {
      _errorMessage = 'Selected task is already closed.';
      notifyListeners();
      return;
    }

    final validationError = _validateReportForm(task);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isReportSubmitting = true;
    _errorMessage = null;
    _submissionMessage = null;
    notifyListeners();

    try {
      final result = await client.createExecutionReport(
        task.id,
        CreateExecutionReportRequestDto(
          requestId: _nextRequestId(),
          reportedBy: _reportAuthor.trim(),
          reportedQuantity: _parseReportQuantity()!,
          outcome: _reportOutcome,
          reason: _normalizedReason(),
        ),
      );
      _submissionMessage = _describeExecutionResult(result);
      _resetReportDraft(
        clearAuthor: false,
        clearMessages: false,
        notify: false,
      );
      await _refreshCollections();
      _selectedTaskId = task.id;
      await _loadSelectedTask();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isReportSubmitting = false;
      notifyListeners();
    }
  }

  bool isSelectedTask(String taskId) => _selectedTaskId == taskId;

  bool isSelectedProblem(String problemId) => _selectedProblemId == problemId;

  Future<void> _loadSelectedTask() async {
    final taskId = _selectedTaskId;
    if (taskId == null || taskId.isEmpty) {
      _selectedTask = null;
      _reports.clear();
      _taskProblems.clear();
      _selectedProblem = null;
      _selectedProblemId = null;
      notifyListeners();
      return;
    }

    _isTaskLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = await client.getTask(taskId);
      final reportsResponse = await client.listTaskReports(taskId);
      final problemsResponse = await client.listProblems(taskId: taskId);

      _selectedTask = task;
      _reports
        ..clear()
        ..addAll(reportsResponse.items);
      _taskProblems
        ..clear()
        ..addAll(problemsResponse.items);

      if (_taskProblems.isEmpty) {
        _selectedProblem = null;
        _selectedProblemId = null;
      } else {
        final preferredProblemId =
            _taskProblems.any((problem) => problem.id == _selectedProblemId)
            ? _selectedProblemId
            : _taskProblems.first.id;
        _selectedProblemId = preferredProblemId;
        _selectedProblem = await client.getProblem(preferredProblemId!);
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isTaskLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCollections() async {
    final responses = await Future.wait([
      client.listTasks(),
      client.listWipEntries(),
      client.listProblems(),
    ]);
    _tasks
      ..clear()
      ..addAll((responses[0] as ApiListResponseDto<TaskSummaryDto>).items);
    _wipEntries
      ..clear()
      ..addAll((responses[1] as ApiListResponseDto<WipEntryDto>).items);
    _allProblems
      ..clear()
      ..addAll((responses[2] as ApiListResponseDto<ProblemSummaryDto>).items);
  }

  Future<void> _syncSelectionAfterTaskChange() async {
    final visible = visibleTasks;
    if (visible.isEmpty) {
      _selectedTaskId = null;
      _selectedTask = null;
      _selectedProblemId = null;
      _selectedProblem = null;
      _reports.clear();
      _taskProblems.clear();
      return;
    }

    final selectedTaskId = _selectedTaskId;
    final nextTaskId = visible.any((task) => task.id == selectedTaskId)
        ? selectedTaskId!
        : visible.first.id;
    if (_selectedTaskId != nextTaskId) {
      _resetReportDraft();
    }
    _selectedTaskId = nextTaskId;
    await _loadSelectedTask();
  }

  String? _validateReportForm(TaskDetailDto task) {
    if (_reportAuthor.trim().isEmpty) {
      return 'Reported by is required.';
    }

    final quantity = _parseReportQuantity();
    if (quantity == null) {
      return _reportOutcome == 'not_completed'
          ? 'Reported quantity must be 0 for not completed.'
          : 'Enter a valid reported quantity.';
    }

    switch (_reportOutcome) {
      case 'completed':
        if (quantity != task.remainingQuantity) {
          return 'Completed must equal remaining quantity: ${task.remainingQuantity}.';
        }
        break;
      case 'partial':
        if (quantity <= 0 || quantity >= task.remainingQuantity) {
          return 'Partial must be above 0 and below ${task.remainingQuantity}.';
        }
        if (_normalizedReason() == null) {
          return 'Reason is required for partial report.';
        }
        break;
      case 'not_completed':
        if (quantity != 0) {
          return 'Not completed keeps reported quantity at 0.';
        }
        if (_normalizedReason() == null) {
          return 'Reason is required for not completed report.';
        }
        break;
      case 'overrun':
        if (quantity <= task.remainingQuantity) {
          return 'Overrun must exceed remaining quantity: ${task.remainingQuantity}.';
        }
        break;
      default:
        return 'Select a supported report outcome.';
    }

    return null;
  }

  double? _parseReportQuantity() {
    final normalized = _reportQuantity.trim();
    if (normalized.isEmpty) {
      return _reportOutcome == 'not_completed' ? 0 : null;
    }
    return double.tryParse(normalized.replaceAll(',', '.'));
  }

  String? _normalizedReason() {
    final value = _reportReason.trim();
    return value.isEmpty ? null : value;
  }

  String _nextRequestId() {
    _requestSequence += 1;
    return 'windows-report-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }

  void _resetReportDraft({
    bool clearAuthor = false,
    bool clearMessages = true,
    bool notify = true,
  }) {
    if (clearAuthor) {
      _reportAuthor = '';
    }
    _reportOutcome = 'completed';
    _reportQuantity = '';
    _reportReason = '';
    if (clearMessages) {
      _clearMessages();
    }
    if (notify) {
      notifyListeners();
    }
  }

  void _clearMessages() {
    _errorMessage = null;
    _submissionMessage = null;
  }

  String _describeExecutionResult(CreateExecutionReportResultDto result) {
    final effect = result.wipEffect;
    if (effect == null || effect.type == 'none') {
      return 'Execution report sent.';
    }
    final balance = effect.balanceQuantity;
    final formattedBalance = balance == null ? '' : ' ($balance pcs)';
    final wipMessage = switch (effect.type) {
      'created' => 'WIP created$formattedBalance.',
      'updated' => 'WIP updated$formattedBalance.',
      'consumed' => 'Existing WIP was consumed.',
      _ => null,
    };
    if (wipMessage == null) {
      return 'Execution report sent.';
    }
    return 'Execution report sent. $wipMessage';
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}
