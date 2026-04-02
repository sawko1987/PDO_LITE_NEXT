import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class ReportsBoardController extends ChangeNotifier {
  ReportsBoardController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  final List<PlanSummaryDto> _plans = [];
  final List<PlanFactReportItemDto> _planFactReport = [];
  final List<ShiftReportItemDto> _shiftReport = [];
  final List<ProblemReportItemDto> _problemReport = [];
  ReportSummaryDto? _summary;
  String? _machineFilter;
  String? _planFactMachineFilter;
  String? _planFactVersionFilter;
  String? _planFactPlanFilter;
  String? _planFactFromDate;
  String? _planFactToDate;
  String? _shiftMachineFilter;
  String? _shiftDate;
  String? _shiftAssigneeFilter;
  String? _problemMachineFilter;
  String? _problemStatusFilter;
  String? _problemTypeFilter;
  String? _problemFromDate;
  String? _problemToDate;
  String _reportTypeFilter = 'summary';
  String? _errorMessage;
  bool _isMachinesLoading = false;
  bool _isPlansLoading = false;
  bool _isSummaryLoading = false;
  bool _isPlanFactLoading = false;
  bool _isShiftLoading = false;
  bool _isProblemLoading = false;
  bool _planFactLoaded = false;
  bool _shiftLoaded = false;
  bool _problemLoaded = false;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<PlanSummaryDto> get plans => List.unmodifiable(_plans);
  List<PlanFactReportItemDto> get planFactReport =>
      List.unmodifiable(_planFactReport);
  List<ShiftReportItemDto> get shiftReport => List.unmodifiable(_shiftReport);
  List<ProblemReportItemDto> get problemReport =>
      List.unmodifiable(_problemReport);
  ReportSummaryDto? get summary => _summary;
  String? get machineFilter => _machineFilter;
  String? get planFactMachineFilter => _planFactMachineFilter;
  String? get planFactVersionFilter => _planFactVersionFilter;
  String? get planFactPlanFilter => _planFactPlanFilter;
  String? get planFactFromDate => _planFactFromDate;
  String? get planFactToDate => _planFactToDate;
  String? get shiftMachineFilter => _shiftMachineFilter;
  String? get shiftDate => _shiftDate;
  String? get shiftAssigneeFilter => _shiftAssigneeFilter;
  String? get problemMachineFilter => _problemMachineFilter;
  String? get problemStatusFilter => _problemStatusFilter;
  String? get problemTypeFilter => _problemTypeFilter;
  String? get problemFromDate => _problemFromDate;
  String? get problemToDate => _problemToDate;
  String get reportTypeFilter => _reportTypeFilter;
  String? get errorMessage => _errorMessage;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isPlansLoading => _isPlansLoading;
  bool get isSummaryLoading => _isSummaryLoading;
  bool get isPlanFactLoading => _isPlanFactLoading;
  bool get isShiftLoading => _isShiftLoading;
  bool get isProblemLoading => _isProblemLoading;
  bool get isBusy =>
      _isMachinesLoading ||
      _isPlansLoading ||
      _isSummaryLoading ||
      _isPlanFactLoading ||
      _isShiftLoading ||
      _isProblemLoading;
  bool get planFactLoaded => _planFactLoaded;
  bool get shiftLoaded => _shiftLoaded;
  bool get problemLoaded => _problemLoaded;

  Future<void> bootstrap() async {
    await Future.wait([loadMachines(), loadPlans(), loadSummary()]);
  }

  Future<void> loadMachines() async {
    _isMachinesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listMachines();
      _machines
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isMachinesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlans() async {
    _isPlansLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listPlans();
      _plans
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPlansLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary({String? machineId}) async {
    if (machineId != null) {
      _machineFilter = _normalizeFilter(machineId);
    }
    _isSummaryLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await client.getReportSummary(machineId: _machineFilter);
      _reportTypeFilter = 'summary';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlanFactReport({
    String? machineId,
    String? versionId,
    String? planId,
    String? fromDate,
    String? toDate,
  }) async {
    if (machineId != null) {
      _planFactMachineFilter = _normalizeFilter(machineId);
    }
    if (versionId != null) {
      _planFactVersionFilter = _normalizeFilter(versionId);
    }
    if (planId != null) {
      _planFactPlanFilter = _normalizeFilter(planId);
    }
    if (fromDate != null) {
      _planFactFromDate = _normalizeFilter(fromDate);
    }
    if (toDate != null) {
      _planFactToDate = _normalizeFilter(toDate);
    }
    _isPlanFactLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.getPlanFactReport(
        machineId: _planFactMachineFilter,
        versionId: _planFactVersionFilter,
        planId: _planFactPlanFilter,
        fromDate: _planFactFromDate,
        toDate: _planFactToDate,
      );
      _planFactReport
        ..clear()
        ..addAll(response.items);
      _planFactLoaded = true;
      _reportTypeFilter = 'plan_fact';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPlanFactLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShiftReport(
    String date, {
    String? machineId,
    String? assigneeId,
  }) async {
    _shiftDate = _normalizeFilter(date);
    if (machineId != null) {
      _shiftMachineFilter = _normalizeFilter(machineId);
    }
    if (assigneeId != null) {
      _shiftAssigneeFilter = _normalizeFilter(assigneeId);
    }
    _isShiftLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.getShiftReport(
        date: _shiftDate ?? date,
        machineId: _shiftMachineFilter,
        assigneeId: _shiftAssigneeFilter,
      );
      _shiftReport
        ..clear()
        ..addAll(response.items);
      _shiftLoaded = true;
      _reportTypeFilter = 'shift';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isShiftLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProblemReport({
    String? machineId,
    String? status,
    String? type,
    String? fromDate,
    String? toDate,
  }) async {
    if (machineId != null) {
      _problemMachineFilter = _normalizeFilter(machineId);
    }
    if (status != null) {
      _problemStatusFilter = _normalizeFilter(status);
    }
    if (type != null) {
      _problemTypeFilter = _normalizeFilter(type);
    }
    if (fromDate != null) {
      _problemFromDate = _normalizeFilter(fromDate);
    }
    if (toDate != null) {
      _problemToDate = _normalizeFilter(toDate);
    }
    _isProblemLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.getProblemReport(
        machineId: _problemMachineFilter,
        status: _problemStatusFilter,
        type: _problemTypeFilter,
        fromDate: _problemFromDate,
        toDate: _problemToDate,
      );
      _problemReport
        ..clear()
        ..addAll(response.items);
      _problemLoaded = true;
      _reportTypeFilter = 'problem';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isProblemLoading = false;
      notifyListeners();
    }
  }

  void setMachineFilter(String? id) {
    _machineFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setPlanFactMachineFilter(String? id) {
    _planFactMachineFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setPlanFactVersionFilter(String? id) {
    _planFactVersionFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setPlanFactPlanFilter(String? id) {
    _planFactPlanFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setPlanFactDateRange(String? fromDate, String? toDate) {
    _planFactFromDate = _normalizeFilter(fromDate);
    _planFactToDate = _normalizeFilter(toDate);
    notifyListeners();
  }

  void setShiftMachineFilter(String? id) {
    _shiftMachineFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setShiftDate(String? date) {
    _shiftDate = _normalizeFilter(date);
    notifyListeners();
  }

  void setShiftAssigneeFilter(String? value) {
    _shiftAssigneeFilter = _normalizeFilter(value);
    notifyListeners();
  }

  void setProblemMachineFilter(String? id) {
    _problemMachineFilter = _normalizeFilter(id);
    notifyListeners();
  }

  void setProblemStatusFilter(String? value) {
    _problemStatusFilter = _normalizeFilter(value);
    notifyListeners();
  }

  void setProblemTypeFilter(String? value) {
    _problemTypeFilter = _normalizeFilter(value);
    notifyListeners();
  }

  void setProblemDateRange(String? fromDate, String? toDate) {
    _problemFromDate = _normalizeFilter(fromDate);
    _problemToDate = _normalizeFilter(toDate);
    notifyListeners();
  }

  void setReportTypeFilter(String value) {
    _reportTypeFilter = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<String> get machineLabels => _machines
      .map((machine) => '${machine.code} - ${machine.name}')
      .toList(growable: false);
  String? _normalizeFilter(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}
