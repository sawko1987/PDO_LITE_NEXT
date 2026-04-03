import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class ArchiveBoardController extends ChangeNotifier {
  ArchiveBoardController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  final List<PlanArchiveItemDto> _plans = [];
  String? _machineFilter;
  String? _fromDate;
  String? _toDate;
  String _status = 'completed';
  PlanDetailDto? _selectedPlan;
  PlanExecutionSummaryDto? _selectedSummary;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _errorMessage;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<PlanArchiveItemDto> get plans => List.unmodifiable(_plans);
  String? get machineFilter => _machineFilter;
  String? get fromDate => _fromDate;
  String? get toDate => _toDate;
  String get status => _status;
  PlanDetailDto? get selectedPlan => _selectedPlan;
  PlanExecutionSummaryDto? get selectedSummary => _selectedSummary;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isBusy => _isLoading || _isDetailLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    await Future.wait([loadMachines(), loadArchive()]);
  }

  Future<void> loadMachines() async {
    try {
      final response = await client.listMachines();
      _machines
        ..clear()
        ..addAll(response.items);
      notifyListeners();
    } catch (error) {
      _errorMessage = _describeError(error);
      notifyListeners();
    }
  }

  Future<void> loadArchive({
    String? machineId,
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    if (machineId != null) {
      _machineFilter = _normalize(machineId);
    }
    if (fromDate != null) {
      _fromDate = _normalize(fromDate);
    }
    if (toDate != null) {
      _toDate = _normalize(toDate);
    }
    if (status != null && status.trim().isNotEmpty) {
      _status = status.trim();
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listArchivePlans(
        machineId: _machineFilter,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _status,
      );
      _plans
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openPlan(String planId) async {
    _isDetailLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        client.getArchivePlan(planId),
        client.getArchivePlanExecutionSummary(planId),
      ]);
      _selectedPlan = results[0] as PlanDetailDto;
      _selectedSummary = results[1] as PlanExecutionSummaryDto;
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void setMachineFilter(String? value) {
    _machineFilter = _normalize(value);
    notifyListeners();
  }

  void setDateRange(String? fromDate, String? toDate) {
    _fromDate = _normalize(fromDate);
    _toDate = _normalize(toDate);
    notifyListeners();
  }

  void setStatus(String value) {
    if (value.trim().isEmpty) {
      return;
    }
    _status = value.trim();
    notifyListeners();
  }

  String? _normalize(String? value) {
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
