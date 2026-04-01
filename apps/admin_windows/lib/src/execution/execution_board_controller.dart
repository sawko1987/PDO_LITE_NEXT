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
  bool _isLoading = false;
  bool _isTaskLoading = false;
  String? _errorMessage;

  List<TaskSummaryDto> get tasks => List.unmodifiable(_tasks);
  List<WipEntryDto> get wipEntries => List.unmodifiable(_wipEntries);
  List<ProblemSummaryDto> get allProblems => List.unmodifiable(_allProblems);
  List<ExecutionReportDto> get reports => List.unmodifiable(_reports);
  List<ProblemSummaryDto> get taskProblems => List.unmodifiable(_taskProblems);
  TaskDetailDto? get selectedTask => _selectedTask;
  ProblemDetailDto? get selectedProblem => _selectedProblem;
  ExecutionTaskFilter get filter => _filter;
  bool get isLoading => _isLoading;
  bool get isTaskLoading => _isTaskLoading;
  bool get isBusy => _isLoading || _isTaskLoading;
  String? get errorMessage => _errorMessage;

  int get activeTaskCount => _tasks.where((task) => !task.isClosed).length;
  int get openProblemCount =>
      _allProblems.where((problem) => problem.isOpen).length;
  int get openWipCount =>
      _wipEntries.where((entry) => entry.blocksCompletion).length;

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
    _selectedTaskId = taskId;
    await _loadSelectedTask();
  }

  Future<void> selectProblem(String problemId) async {
    _selectedProblemId = problemId;
    _selectedProblem = null;
    _errorMessage = null;
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
    notifyListeners();
    await _syncSelectionAfterTaskChange();
    notifyListeners();
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
    _selectedTaskId = nextTaskId;
    await _loadSelectedTask();
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}
