import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class WipBoardController extends ChangeNotifier {
  WipBoardController({required this.client});

  final AdminBackendClient client;

  final List<WipEntryDto> _entries = [];
  String? _selectedEntryId;
  String? _machineFilter;
  String? _versionFilter;
  String? _statusFilter;
  String? _workshopFilter;
  String? _operationFilter;
  String? _taskFilter;
  String? _errorMessage;
  bool _isLoading = false;

  List<WipEntryDto> get entries => List.unmodifiable(_entries);
  String? get selectedEntryId => _selectedEntryId;
  String? get machineFilter => _machineFilter;
  String? get versionFilter => _versionFilter;
  String? get statusFilter => _statusFilter;
  String? get workshopFilter => _workshopFilter;
  String? get operationFilter => _operationFilter;
  String? get taskFilter => _taskFilter;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  WipEntryDto? get selectedEntry => visibleEntries
      .cast<WipEntryDto?>()
      .firstWhere((item) => item?.id == _selectedEntryId, orElse: () => null);

  List<WipEntryDto> get visibleEntries => _entries
      .where((entry) {
        if (_machineFilter != null &&
            _machineFilter!.isNotEmpty &&
            entry.machineId != _machineFilter) {
          return false;
        }
        if (_versionFilter != null &&
            _versionFilter!.isNotEmpty &&
            entry.versionId != _versionFilter) {
          return false;
        }
        if (_statusFilter != null &&
            _statusFilter!.isNotEmpty &&
            entry.status != _statusFilter) {
          return false;
        }
        if (_workshopFilter != null &&
            _workshopFilter!.isNotEmpty &&
            (entry.workshop ?? '') != _workshopFilter) {
          return false;
        }
        if (_operationFilter != null &&
            _operationFilter!.isNotEmpty &&
            (entry.operationName ?? '') != _operationFilter) {
          return false;
        }
        if (_taskFilter != null &&
            _taskFilter!.isNotEmpty &&
            entry.taskId != _taskFilter) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<String> get machineOptions =>
      _entries.map((entry) => entry.machineId).toSet().toList()..sort();
  List<String> get versionOptions =>
      _entries.map((entry) => entry.versionId).toSet().toList()..sort();
  List<String> get statusOptions =>
      _entries.map((entry) => entry.status).toSet().toList()..sort();
  List<String> get workshopOptions =>
      _entries
          .map((entry) => entry.workshop ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  List<String> get operationOptions =>
      _entries
          .map((entry) => entry.operationName ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  Future<void> bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listWipEntries();
      _entries
        ..clear()
        ..addAll(response.items);
      _syncSelection();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectEntry(String? entryId) {
    _selectedEntryId = entryId;
    _errorMessage = null;
    notifyListeners();
  }

  void openTaskScope(String? taskId) {
    _taskFilter = taskId;
    _syncSelection();
    _errorMessage = null;
    notifyListeners();
  }

  void setMachineFilter(String? value) {
    _machineFilter = _normalizeFilter(value);
    _syncSelection();
    notifyListeners();
  }

  void setVersionFilter(String? value) {
    _versionFilter = _normalizeFilter(value);
    _syncSelection();
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = _normalizeFilter(value);
    _syncSelection();
    notifyListeners();
  }

  void setWorkshopFilter(String? value) {
    _workshopFilter = _normalizeFilter(value);
    _syncSelection();
    notifyListeners();
  }

  void setOperationFilter(String? value) {
    _operationFilter = _normalizeFilter(value);
    _syncSelection();
    notifyListeners();
  }

  void clearFilters() {
    _machineFilter = null;
    _versionFilter = null;
    _statusFilter = null;
    _workshopFilter = null;
    _operationFilter = null;
    _taskFilter = null;
    _syncSelection();
    notifyListeners();
  }

  void _syncSelection() {
    final visible = visibleEntries;
    if (visible.isEmpty) {
      _selectedEntryId = null;
      return;
    }
    if (_selectedEntryId != null &&
        visible.any((entry) => entry.id == _selectedEntryId)) {
      return;
    }
    _selectedEntryId = visible.first.id;
  }

  String? _normalizeFilter(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Непредвиденная ошибка: $error';
  }
}
