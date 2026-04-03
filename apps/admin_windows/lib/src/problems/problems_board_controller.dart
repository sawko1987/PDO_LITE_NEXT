import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class ProblemsBoardController extends ChangeNotifier {
  ProblemsBoardController({
    required this.client,
    this.actorId = 'supervisor-1',
  });

  final AdminBackendClient client;
  final String actorId;

  final List<ProblemSummaryDto> _problems = [];
  final List<TaskSummaryDto> _tasks = [];
  String? _selectedProblemId;
  ProblemDetailDto? _selectedProblem;
  String? _statusFilter;
  String? _typeFilter;
  String? _machineFilter;
  String? _taskFilter;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _isSaving = false;
  int _requestSequence = 0;

  List<ProblemSummaryDto> get problems => List.unmodifiable(_problems);
  List<TaskSummaryDto> get tasks => List.unmodifiable(_tasks);
  ProblemDetailDto? get selectedProblem => _selectedProblem;
  String? get selectedProblemId => _selectedProblemId;
  String? get statusFilter => _statusFilter;
  String? get typeFilter => _typeFilter;
  String? get machineFilter => _machineFilter;
  String? get taskFilter => _taskFilter;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;

  List<ProblemSummaryDto> get visibleProblems => _problems
      .where((problem) {
        if (_statusFilter != null &&
            _statusFilter!.isNotEmpty &&
            problem.status != _statusFilter) {
          return false;
        }
        if (_typeFilter != null &&
            _typeFilter!.isNotEmpty &&
            problem.type != _typeFilter) {
          return false;
        }
        if (_machineFilter != null &&
            _machineFilter!.isNotEmpty &&
            problem.machineId != _machineFilter) {
          return false;
        }
        if (_taskFilter != null &&
            _taskFilter!.isNotEmpty &&
            problem.taskId != _taskFilter) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<String> get statusOptions =>
      _problems.map((problem) => problem.status).toSet().toList()..sort();
  List<String> get typeOptions =>
      _problems.map((problem) => problem.type).toSet().toList()..sort();
  List<String> get machineOptions =>
      _problems.map((problem) => problem.machineId).toSet().toList()..sort();

  Future<void> bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      final responses = await Future.wait([
        client.listProblems(),
        client.listTasks(),
      ]);
      _problems
        ..clear()
        ..addAll((responses[0] as ApiListResponseDto<ProblemSummaryDto>).items);
      _tasks
        ..clear()
        ..addAll((responses[1] as ApiListResponseDto<TaskSummaryDto>).items);
      await _syncSelection();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProblem(String? problemId) async {
    _selectedProblemId = problemId;
    _selectedProblem = null;
    _clearMessages();
    notifyListeners();
    if (problemId == null || problemId.isEmpty) {
      return;
    }
    await _loadProblemDetail(problemId);
  }

  Future<void> openTaskScope(String? taskId) async {
    _taskFilter = _normalizeFilter(taskId);
    _selectedProblemId = null;
    _selectedProblem = null;
    _clearMessages();
    await _syncSelection();
    notifyListeners();
  }

  Future<void> setStatusFilter(String? value) async {
    _statusFilter = _normalizeFilter(value);
    await _syncSelection();
    notifyListeners();
  }

  Future<void> setTypeFilter(String? value) async {
    _typeFilter = _normalizeFilter(value);
    await _syncSelection();
    notifyListeners();
  }

  Future<void> setMachineFilter(String? value) async {
    _machineFilter = _normalizeFilter(value);
    await _syncSelection();
    notifyListeners();
  }

  Future<void> setTaskFilter(String? value) async {
    _taskFilter = _normalizeFilter(value);
    await _syncSelection();
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _statusFilter = null;
    _typeFilter = null;
    _machineFilter = null;
    _taskFilter = null;
    await _syncSelection();
    notifyListeners();
  }

  Future<ProblemDetailDto?> createProblem({
    required String taskId,
    required String type,
    required String title,
    required String description,
  }) async {
    if (taskId.trim().isEmpty ||
        type.trim().isEmpty ||
        title.trim().isEmpty ||
        description.trim().isEmpty) {
      _errorMessage =
          'Fill task, type, title, and description before creating a problem.';
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await client.createProblem(
        taskId,
        CreateProblemRequestDto(
          requestId: _nextRequestId('desktop-problem'),
          createdBy: actorId,
          type: type,
          title: title.trim(),
          description: description.trim(),
        ),
      );
      _successMessage = 'Problem ${detail.title ?? detail.id} created.';
      await refresh();
      await selectProblem(detail.id);
      return detail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ProblemDetailDto?> addMessage(String message) async {
    final problem = _selectedProblem;
    if (problem == null) {
      _errorMessage = 'Select a problem before sending a message.';
      notifyListeners();
      return null;
    }
    if (message.trim().isEmpty) {
      _errorMessage = 'Сообщение не может быть пустым.';
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await client.addProblemMessage(
        problem.id,
        AddProblemMessageRequestDto(
          requestId: _nextRequestId('desktop-problem-message'),
          authorId: actorId,
          message: message.trim(),
        ),
      );
      _successMessage = 'Problem message sent.';
      await refresh();
      await selectProblem(detail.id);
      return detail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ProblemDetailDto?> transitionSelectedProblem(String toStatus) async {
    final problem = _selectedProblem;
    if (problem == null) {
      _errorMessage = 'Select a problem before changing status.';
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await client.transitionProblem(
        problem.id,
        TransitionProblemRequestDto(
          requestId: _nextRequestId('desktop-problem-transition'),
          changedBy: actorId,
          toStatus: toStatus,
        ),
      );
      _successMessage = 'Problem moved to ${detail.status}.';
      await refresh();
      await selectProblem(detail.id);
      return detail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _syncSelection() async {
    final visible = visibleProblems;
    if (visible.isEmpty) {
      _selectedProblemId = null;
      _selectedProblem = null;
      return;
    }
    final nextProblemId =
        _selectedProblemId != null &&
            visible.any((problem) => problem.id == _selectedProblemId)
        ? _selectedProblemId!
        : visible.first.id;
    if (nextProblemId == _selectedProblemId && _selectedProblem != null) {
      return;
    }
    _selectedProblemId = nextProblemId;
    await _loadProblemDetail(nextProblemId);
  }

  Future<void> _loadProblemDetail(String problemId) async {
    try {
      _selectedProblem = await client.getProblem(problemId);
    } catch (error) {
      _errorMessage = _describeError(error);
    }
  }

  String? _normalizeFilter(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _nextRequestId(String prefix) {
    _requestSequence += 1;
    return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Непредвиденная ошибка: $error';
  }
}
