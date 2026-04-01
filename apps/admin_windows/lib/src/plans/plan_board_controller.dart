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
  final Map<String, PlanningTreeNode> _planningNodeIndex = {};
  String? _selectedMachineId;
  String? _selectedVersionId;
  String? _selectedPlanningNodeId;
  String _planTitle = '';
  String _bulkAddQuantity = '1';
  PlanDetailDto? _activePlan;
  PlanCompletionDecisionDto? _completionDecision;
  PlanReleaseResultDto? _releaseResult;
  PlanCompletionResultDto? _completionResult;
  PlanningTreeNode? _planningTreeRoot;
  BulkDraftAddResult? _lastBulkDraftAddResult;
  String? _errorMessage;
  bool _isMachinesLoading = false;
  bool _isPlansLoading = false;
  bool _isVersionsLoading = false;
  bool _isPlanningSourceLoading = false;
  bool _isSavingPlan = false;
  bool _isReleasingPlan = false;
  bool _isCheckingCompletion = false;
  bool _isCompletingPlan = false;
  bool _isWipLoading = false;
  int _requestSequence = 0;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<MachineVersionSummaryDto> get versions => List.unmodifiable(_versions);
  List<PlanningSourceOccurrenceDto> get planningSource =>
      List.unmodifiable(_planningSource);
  List<PlanSummaryDto> get plans => List.unmodifiable(_plans);
  List<WipEntryDto> get wipEntries => List.unmodifiable(_wipEntries);
  PlanningTreeNode? get planningTreeRoot => _planningTreeRoot;
  String? get selectedMachineId => _selectedMachineId;
  String? get selectedVersionId => _selectedVersionId;
  String? get selectedPlanningNodeId => _selectedPlanningNodeId;
  PlanningTreeNode? get selectedPlanningNode => _selectedPlanningNodeId == null
      ? null
      : _planningNodeIndex[_selectedPlanningNodeId];
  String get planTitle => _planTitle;
  String get bulkAddQuantity => _bulkAddQuantity;
  PlanDetailDto? get activePlan => _activePlan;
  PlanCompletionDecisionDto? get completionDecision => _completionDecision;
  PlanReleaseResultDto? get releaseResult => _releaseResult;
  PlanCompletionResultDto? get completionResult => _completionResult;
  BulkDraftAddResult? get lastBulkDraftAddResult => _lastBulkDraftAddResult;
  String? get errorMessage => _errorMessage;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isPlansLoading => _isPlansLoading;
  bool get isVersionsLoading => _isVersionsLoading;
  bool get isPlanningSourceLoading => _isPlanningSourceLoading;
  bool get isSavingPlan => _isSavingPlan;
  bool get isReleasingPlan => _isReleasingPlan;
  bool get isCheckingCompletion => _isCheckingCompletion;
  bool get isCompletingPlan => _isCompletingPlan;
  bool get isWipLoading => _isWipLoading;
  bool get isBusy =>
      _isMachinesLoading ||
      _isPlansLoading ||
      _isVersionsLoading ||
      _isPlanningSourceLoading ||
      _isSavingPlan ||
      _isReleasingPlan ||
      _isCheckingCompletion ||
      _isCompletingPlan ||
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

  BulkAddPreview? get bulkAddPreview {
    final node = selectedPlanningNode;
    if (node == null) {
      return null;
    }
    final totalOccurrenceCount = node.descendantOccurrenceIds.length;
    final newOccurrenceCount = node.descendantOccurrenceIds
        .where((occurrenceId) => !_draftQuantities.containsKey(occurrenceId))
        .length;
    return BulkAddPreview(
      selectedNodeId: node.id,
      selectedNodeLabel: node.label,
      totalOccurrenceCount: totalOccurrenceCount,
      newOccurrenceCount: newOccurrenceCount,
      skippedOccurrenceCount: totalOccurrenceCount - newOccurrenceCount,
    );
  }

  bool get canBulkAddSelectedNode =>
      !_isSavingPlan &&
      !_isPlanningSourceLoading &&
      selectedPlanningNode != null &&
      (_parseQuantity(_bulkAddQuantity) ?? 0) > 0;

  bool get canReleaseActivePlan =>
      !_isSavingPlan &&
      !_isReleasingPlan &&
      _activePlan != null &&
      _activePlan!.canRelease;

  bool get canCheckActivePlanCompletion =>
      !_isCheckingCompletion &&
      !_isCompletingPlan &&
      _activePlan != null &&
      _activePlan!.status == 'released';

  bool get canConfirmActivePlanCompletion =>
      !_isCheckingCompletion &&
      !_isCompletingPlan &&
      _activePlan != null &&
      _activePlan!.status == 'released' &&
      (_completionDecision?.canComplete ?? false);

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
        _planningTreeRoot = null;
        _planningNodeIndex.clear();
        _selectedPlanningNodeId = null;
        _lastBulkDraftAddResult = null;
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
    _selectedPlanningNodeId = null;
    _versions.clear();
    _planningSource.clear();
    _draftQuantities.clear();
    _planningTreeRoot = null;
    _planningNodeIndex.clear();
    _activePlan = null;
    _completionDecision = null;
    _releaseResult = null;
    _completionResult = null;
    _bulkAddQuantity = '1';
    _lastBulkDraftAddResult = null;
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
    _selectedPlanningNodeId = null;
    _planningSource.clear();
    _draftQuantities.clear();
    _planningTreeRoot = null;
    _planningNodeIndex.clear();
    _activePlan = null;
    _completionDecision = null;
    _releaseResult = null;
    _completionResult = null;
    _bulkAddQuantity = '1';
    _lastBulkDraftAddResult = null;
    _errorMessage = null;
    notifyListeners();

    if (versionId == null || versionId.isEmpty) {
      await loadWipEntries();
      return;
    }
    await _loadPlanningSource();
    await loadWipEntries();
  }

  Future<void> openMachineVersion({
    required String machineId,
    String? versionId,
  }) async {
    if (_machines.isEmpty) {
      await loadMachines();
    }

    if (_selectedMachineId != machineId) {
      await selectMachine(machineId);
    } else if (_versions.isEmpty) {
      await selectMachine(machineId);
    }

    if (versionId != null &&
        versionId.isNotEmpty &&
        _selectedVersionId != versionId) {
      await selectVersion(versionId);
    }
  }

  void setPlanTitle(String value) {
    _planTitle = value;
    _errorMessage = null;
    notifyListeners();
  }

  void selectPlanningNode(String? nodeId) {
    if (nodeId != null && !_planningNodeIndex.containsKey(nodeId)) {
      return;
    }
    _selectedPlanningNodeId = nodeId;
    _errorMessage = null;
    notifyListeners();
  }

  void setBulkAddQuantity(String value) {
    _bulkAddQuantity = value;
    _errorMessage = null;
    notifyListeners();
  }

  void addOccurrenceToDraft(PlanningSourceOccurrenceDto occurrence) {
    _draftQuantities.putIfAbsent(occurrence.id, () => 1);
    _lastBulkDraftAddResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void removeOccurrenceFromDraft(String occurrenceId) {
    _draftQuantities.remove(occurrenceId);
    _lastBulkDraftAddResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void updateRequestedQuantity(String occurrenceId, String rawValue) {
    final parsed = _parseQuantity(rawValue);
    _draftQuantities[occurrenceId] = parsed ?? 0;
    _lastBulkDraftAddResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void addSelectedPlanningNodeToDraft() {
    final node = selectedPlanningNode;
    if (node == null) {
      _errorMessage = 'Select a machine branch, node, place, or detail first.';
      notifyListeners();
      return;
    }

    final parsedQuantity = _parseQuantity(_bulkAddQuantity);
    if (parsedQuantity == null || parsedQuantity <= 0) {
      _errorMessage = 'Enter a positive quantity for the selected branch.';
      notifyListeners();
      return;
    }

    var addedOccurrenceCount = 0;
    var skippedOccurrenceCount = 0;
    for (final occurrence in _planningSource) {
      if (!node.descendantOccurrenceIds.contains(occurrence.id)) {
        continue;
      }
      if (_draftQuantities.containsKey(occurrence.id)) {
        skippedOccurrenceCount += 1;
        continue;
      }
      _draftQuantities[occurrence.id] = parsedQuantity;
      addedOccurrenceCount += 1;
    }

    _lastBulkDraftAddResult = BulkDraftAddResult(
      selectedNodeLabel: node.label,
      totalOccurrenceCount: node.descendantOccurrenceIds.length,
      addedOccurrenceCount: addedOccurrenceCount,
      skippedOccurrenceCount: skippedOccurrenceCount,
      requestedQuantity: parsedQuantity,
    );
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
    _completionDecision = null;
    _releaseResult = null;
    _completionResult = null;
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
      _completionDecision = null;
      _draftQuantities.clear();
      _planTitle = '';
      _lastBulkDraftAddResult = null;
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
      _completionDecision = null;
      _completionResult = null;
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
    _completionDecision = null;
    _completionResult = null;
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
      _completionDecision = null;
      await Future.wait([loadPlans(), loadWipEntries()]);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isReleasingPlan = false;
      notifyListeners();
    }
  }

  Future<void> checkActivePlanCompletion() async {
    final plan = _activePlan;
    if (plan == null || plan.status != 'released') {
      _errorMessage = 'Selected plan is not ready for completion check.';
      notifyListeners();
      return;
    }

    _isCheckingCompletion = true;
    _errorMessage = null;
    _completionResult = null;
    notifyListeners();

    try {
      _completionDecision = await client.getPlanCompletionDecision(plan.id);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isCheckingCompletion = false;
      notifyListeners();
    }
  }

  Future<void> completeActivePlan() async {
    final plan = _activePlan;
    if (plan == null || plan.status != 'released') {
      _errorMessage = 'Selected plan cannot be completed.';
      notifyListeners();
      return;
    }
    if (!(_completionDecision?.canComplete ?? false)) {
      _errorMessage =
          'Run completion check first and resolve any blockers before confirming.';
      notifyListeners();
      return;
    }

    _isCompletingPlan = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _completionResult = await client.completePlan(
        plan.id,
        CompletePlanRequestDto(
          requestId: _nextRequestId('complete-plan'),
          completedBy: 'supervisor-1',
        ),
      );
      _activePlan = await client.getPlan(plan.id);
      _completionDecision = await client.getPlanCompletionDecision(plan.id);
      await Future.wait([loadPlans(), loadWipEntries()]);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isCompletingPlan = false;
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
      _rebuildPlanningTree();
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

  void _rebuildPlanningTree() {
    _planningNodeIndex.clear();
    _planningTreeRoot = null;
    _selectedPlanningNodeId = null;
    _lastBulkDraftAddResult = null;

    if (_planningSource.isEmpty) {
      return;
    }

    final rootBuilder = _MutablePlanningTreeNode(
      id: 'root',
      label: _resolveRootLabel(),
      pathKey: '',
      occurrenceIds: <String>{},
    );

    for (final occurrence in _planningSource) {
      final segments = occurrence.pathKey
          .split('/')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);

      rootBuilder.occurrenceIds.add(occurrence.id);

      if (segments.isEmpty) {
        rootBuilder.children.putIfAbsent(
          'occ:${occurrence.id}',
          () => _MutablePlanningTreeNode(
            id: 'occ:${occurrence.id}',
            label: occurrence.displayName,
            pathKey: occurrence.pathKey,
            occurrenceIds: {occurrence.id},
            occurrence: occurrence,
          ),
        );
        continue;
      }

      var current = rootBuilder;
      for (var index = 0; index < segments.length; index += 1) {
        final segment = segments[index];
        final currentPath = segments.take(index + 1).join('/');
        final isLeaf = index == segments.length - 1;
        if (isLeaf) {
          current.children.putIfAbsent(
            'occ:${occurrence.id}',
            () => _MutablePlanningTreeNode(
              id: 'occ:${occurrence.id}',
              label: occurrence.displayName,
              pathKey: occurrence.pathKey,
              occurrenceIds: {occurrence.id},
              occurrence: occurrence,
            ),
          );
          continue;
        }
        final child = current.children.putIfAbsent(
          'node:$currentPath',
          () => _MutablePlanningTreeNode(
            id: 'node:$currentPath',
            label: segment,
            pathKey: currentPath,
            occurrenceIds: <String>{},
          ),
        );
        child.occurrenceIds.add(occurrence.id);
        current = child;
      }
    }

    _planningTreeRoot = _freezePlanningTree(rootBuilder, depth: 0);
    _selectedPlanningNodeId = _planningTreeRoot?.id;
  }

  PlanningTreeNode _freezePlanningTree(
    _MutablePlanningTreeNode builder, {
    required int depth,
  }) {
    final children =
        builder.children.values
            .map((child) => _freezePlanningTree(child, depth: depth + 1))
            .toList(growable: false)
          ..sort((left, right) {
            if (left.isLeaf != right.isLeaf) {
              return left.isLeaf ? 1 : -1;
            }
            return left.label.toLowerCase().compareTo(
              right.label.toLowerCase(),
            );
          });

    final node = PlanningTreeNode(
      id: builder.id,
      label: builder.label,
      pathKey: builder.pathKey,
      depth: depth,
      descendantOccurrenceIds: List.unmodifiable(
        builder.occurrenceIds.toList(growable: false)..sort(),
      ),
      children: children,
      occurrence: builder.occurrence,
    );
    _planningNodeIndex[node.id] = node;
    return node;
  }

  String _resolveRootLabel() {
    final machine = _machines.cast<MachineSummaryDto?>().firstWhere(
      (item) => item?.id == _selectedMachineId,
      orElse: () => null,
    );
    if (machine == null) {
      return 'Whole machine';
    }
    return 'Whole machine: ${machine.code}';
  }

  double? _parseQuantity(String rawValue) {
    return double.tryParse(rawValue.replaceAll(',', '.'));
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

class PlanningTreeNode {
  const PlanningTreeNode({
    required this.id,
    required this.label,
    required this.pathKey,
    required this.depth,
    required this.descendantOccurrenceIds,
    required this.children,
    this.occurrence,
  });

  final String id;
  final String label;
  final String pathKey;
  final int depth;
  final List<String> descendantOccurrenceIds;
  final List<PlanningTreeNode> children;
  final PlanningSourceOccurrenceDto? occurrence;

  bool get isLeaf => occurrence != null;
}

class BulkAddPreview {
  const BulkAddPreview({
    required this.selectedNodeId,
    required this.selectedNodeLabel,
    required this.totalOccurrenceCount,
    required this.newOccurrenceCount,
    required this.skippedOccurrenceCount,
  });

  final String selectedNodeId;
  final String selectedNodeLabel;
  final int totalOccurrenceCount;
  final int newOccurrenceCount;
  final int skippedOccurrenceCount;
}

class BulkDraftAddResult {
  const BulkDraftAddResult({
    required this.selectedNodeLabel,
    required this.totalOccurrenceCount,
    required this.addedOccurrenceCount,
    required this.skippedOccurrenceCount,
    required this.requestedQuantity,
  });

  final String selectedNodeLabel;
  final int totalOccurrenceCount;
  final int addedOccurrenceCount;
  final int skippedOccurrenceCount;
  final double requestedQuantity;
}

class _MutablePlanningTreeNode {
  _MutablePlanningTreeNode({
    required this.id,
    required this.label,
    required this.pathKey,
    required Set<String> occurrenceIds,
    this.occurrence,
  }) : occurrenceIds = occurrenceIds;

  final String id;
  final String label;
  final String pathKey;
  final Set<String> occurrenceIds;
  final Map<String, _MutablePlanningTreeNode> children = {};
  final PlanningSourceOccurrenceDto? occurrence;
}
