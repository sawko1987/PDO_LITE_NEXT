import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class PlanBoardController extends ChangeNotifier {
  PlanBoardController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  final List<MachineVersionSummaryDto> _versions = [];
  final List<PlanningSourceOccurrenceDto> _planningSource = [];
  final List<PlanSummaryDto> _plans = [];
  final List<WipEntryDto> _wipEntries = [];
  final Map<String, double> _draftQuantities = {};
  String? _selectedMachineId;
  String? _selectedVersionId;
  String _planTitle = '';
  PlanDetailDto? _activePlan;
  PlanReleaseResultDto? _releaseResult;
  String? _errorMessage;
  bool _isMachinesLoading = false;
  bool _isPlansLoading = false;
  bool _isVersionsLoading = false;
  bool _isPlanningSourceLoading = false;
  bool _isSavingPlan = false;
  bool _isReleasingPlan = false;
  bool _isWipLoading = false;
  int _requestSequence = 0;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<MachineVersionSummaryDto> get versions => List.unmodifiable(_versions);
  List<PlanningSourceOccurrenceDto> get planningSource =>
      List.unmodifiable(_planningSource);
  List<PlanSummaryDto> get plans => List.unmodifiable(_plans);
  List<WipEntryDto> get wipEntries => List.unmodifiable(_wipEntries);
  String? get selectedMachineId => _selectedMachineId;
  String? get selectedVersionId => _selectedVersionId;
  String get planTitle => _planTitle;
  PlanDetailDto? get activePlan => _activePlan;
  PlanReleaseResultDto? get releaseResult => _releaseResult;
  String? get errorMessage => _errorMessage;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isPlansLoading => _isPlansLoading;
  bool get isVersionsLoading => _isVersionsLoading;
  bool get isPlanningSourceLoading => _isPlanningSourceLoading;
  bool get isSavingPlan => _isSavingPlan;
  bool get isReleasingPlan => _isReleasingPlan;
  bool get isWipLoading => _isWipLoading;
  bool get isBusy =>
      _isMachinesLoading ||
      _isPlansLoading ||
      _isVersionsLoading ||
      _isPlanningSourceLoading ||
      _isSavingPlan ||
      _isReleasingPlan ||
      _isWipLoading;

  List<WipEntryDto> get visibleWipEntries {
    final machineId = _activePlan?.machineId ?? _selectedMachineId;
    final versionId = _activePlan?.versionId ?? _selectedVersionId;
    return _wipEntries
        .where((entry) {
          if (machineId != null &&
              machineId.isNotEmpty &&
              entry.machineId != machineId) {
            return false;
          }
          if (versionId != null &&
              versionId.isNotEmpty &&
              entry.versionId != versionId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<DraftPlanSelection> get draftSelections => _draftQuantities.entries
      .map(
        (entry) => DraftPlanSelection(
          occurrence: _planningSource.firstWhere(
            (item) => item.id == entry.key,
            orElse: () => PlanningSourceOccurrenceDto(
              id: entry.key,
              catalogItemId: '',
              displayName: entry.key,
              pathKey: entry.key,
              quantityPerMachine: 0,
              operationCount: 0,
            ),
          ),
          requestedQuantity: entry.value,
        ),
      )
      .toList(growable: false);

  bool isSelectedOccurrence(String occurrenceId) {
    return _draftQuantities.containsKey(occurrenceId);
  }

  bool get canCreatePlan =>
      !_isSavingPlan &&
      !_isReleasingPlan &&
      (_selectedMachineId?.isNotEmpty ?? false) &&
      (_selectedVersionId?.isNotEmpty ?? false) &&
      _planTitle.trim().isNotEmpty &&
      _draftQuantities.isNotEmpty &&
      !_draftQuantities.values.any((value) => value <= 0);

  bool get canReleaseActivePlan =>
      !_isSavingPlan &&
      !_isReleasingPlan &&
      _activePlan != null &&
      _activePlan!.canRelease;

  Future<void> bootstrap() async {
    await Future.wait([loadMachines(), loadPlans(), loadWipEntries()]);
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
      if (_selectedMachineId != null &&
          !_machines.any((machine) => machine.id == _selectedMachineId)) {
        _selectedMachineId = null;
        _selectedVersionId = null;
        _versions.clear();
        _planningSource.clear();
        _draftQuantities.clear();
      }
      await loadWipEntries();
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

  Future<void> selectMachine(String? machineId) async {
    _selectedMachineId = machineId;
    _selectedVersionId = null;
    _versions.clear();
    _planningSource.clear();
    _draftQuantities.clear();
    _activePlan = null;
    _releaseResult = null;
    _errorMessage = null;
    notifyListeners();

    if (machineId == null || machineId.isEmpty) {
      await loadWipEntries();
      return;
    }

    _isVersionsLoading = true;
    notifyListeners();
    try {
      final response = await client.listMachineVersions(machineId);
      _versions
        ..clear()
        ..addAll(response.items);
      final machine = _machines.firstWhere(
        (item) => item.id == machineId,
        orElse: () => const MachineSummaryDto(id: '', code: '', name: ''),
      );
      final preferredVersionId =
          machine.activeVersionId ??
          (_versions.isNotEmpty ? _versions.first.id : null);
      _selectedVersionId = preferredVersionId;
      if (preferredVersionId != null && preferredVersionId.isNotEmpty) {
        await _loadPlanningSource();
      }
      await loadWipEntries();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isVersionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectVersion(String? versionId) async {
    _selectedVersionId = versionId;
    _planningSource.clear();
    _draftQuantities.clear();
    _activePlan = null;
    _releaseResult = null;
    _errorMessage = null;
    notifyListeners();

    if (versionId == null || versionId.isEmpty) {
      await loadWipEntries();
      return;
    }
    await _loadPlanningSource();
    await loadWipEntries();
  }

  void setPlanTitle(String value) {
    _planTitle = value;
    _errorMessage = null;
    notifyListeners();
  }

  void addOccurrenceToDraft(PlanningSourceOccurrenceDto occurrence) {
    _draftQuantities.putIfAbsent(occurrence.id, () => 1);
    _errorMessage = null;
    notifyListeners();
  }

  void removeOccurrenceFromDraft(String occurrenceId) {
    _draftQuantities.remove(occurrenceId);
    _errorMessage = null;
    notifyListeners();
  }

  void updateRequestedQuantity(String occurrenceId, String rawValue) {
    final parsed = double.tryParse(rawValue.replaceAll(',', '.'));
    _draftQuantities[occurrenceId] = parsed ?? 0;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> createPlan() async {
    if (!canCreatePlan) {
      _errorMessage =
          'Select machine and version, set title, and add at least one occurrence with positive quantity.';
      notifyListeners();
      return;
    }

    _isSavingPlan = true;
    _errorMessage = null;
    _releaseResult = null;
    notifyListeners();

    try {
      final detail = await client.createPlan(
        CreatePlanRequestDto(
          requestId: _nextRequestId('create-plan'),
          machineId: _selectedMachineId!,
          versionId: _selectedVersionId!,
          title: _planTitle.trim(),
          items: _draftQuantities.entries
              .map(
                (entry) => CreatePlanItemRequestDto(
                  structureOccurrenceId: entry.key,
                  requestedQuantity: entry.value,
                ),
              )
              .toList(growable: false),
        ),
      );
      _activePlan = detail;
      _draftQuantities.clear();
      _planTitle = '';
      await Future.wait([loadPlans(), loadWipEntries()]);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSavingPlan = false;
      notifyListeners();
    }
  }

  Future<void> openPlan(String planId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      _activePlan = await client.getPlan(planId);
      await loadWipEntries();
    } catch (error) {
      _errorMessage = _describeError(error);
      notifyListeners();
    }
  }

  Future<void> releaseActivePlan() async {
    final plan = _activePlan;
    if (plan == null || !plan.canRelease) {
      _errorMessage = 'Selected plan cannot be released.';
      notifyListeners();
      return;
    }

    _isReleasingPlan = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _releaseResult = await client.releasePlan(
        plan.id,
        ReleasePlanRequestDto(
          requestId: _nextRequestId('release-plan'),
          releasedBy: 'planner-1',
        ),
      );
      _activePlan = await client.getPlan(plan.id);
      await Future.wait([loadPlans(), loadWipEntries()]);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isReleasingPlan = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlanningSource() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    if (machineId == null ||
        machineId.isEmpty ||
        versionId == null ||
        versionId.isEmpty) {
      return;
    }

    _isPlanningSourceLoading = true;
    notifyListeners();

    try {
      final response = await client.listPlanningSource(machineId, versionId);
      _planningSource
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPlanningSourceLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWipEntries() async {
    _isWipLoading = true;
    notifyListeners();

    try {
      final response = await client.listWipEntries();
      _wipEntries
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isWipLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }

  String _nextRequestId(String prefix) {
    _requestSequence += 1;
    return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}

class DraftPlanSelection {
  const DraftPlanSelection({
    required this.occurrence,
    required this.requestedQuantity,
  });

  final PlanningSourceOccurrenceDto occurrence;
  final double requestedQuantity;
}
