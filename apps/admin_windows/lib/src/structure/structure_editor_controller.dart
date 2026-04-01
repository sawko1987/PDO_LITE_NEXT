import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class StructureEditorController extends ChangeNotifier {
  StructureEditorController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  final List<MachineVersionSummaryDto> _versions = [];
  final Map<String, StructureTreeNode> _nodeIndex = {};
  MachineVersionDetailDto? _versionDetail;
  StructureTreeNode? _treeRoot;
  String? _selectedMachineId;
  String? _selectedVersionId;
  String? _selectedOccurrenceId;
  String? _selectedOperationId;
  String? _errorMessage;
  String? _successMessage;
  bool _isMachinesLoading = false;
  bool _isVersionsLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  int _requestSequence = 0;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<MachineVersionSummaryDto> get versions => List.unmodifiable(_versions);
  MachineVersionDetailDto? get versionDetail => _versionDetail;
  StructureTreeNode? get treeRoot => _treeRoot;
  String? get selectedMachineId => _selectedMachineId;
  String? get selectedVersionId => _selectedVersionId;
  String? get selectedOccurrenceId => _selectedOccurrenceId;
  String? get selectedOperationId => _selectedOperationId;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isVersionsLoading => _isVersionsLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  bool get isBusy =>
      _isMachinesLoading || _isVersionsLoading || _isDetailLoading || _isSaving;

  MachineSummaryDto? get selectedMachine => _machines
      .cast<MachineSummaryDto?>()
      .firstWhere((item) => item?.id == _selectedMachineId, orElse: () => null);

  MachineVersionSummaryDto? get selectedVersion => _versions
      .cast<MachineVersionSummaryDto?>()
      .firstWhere((item) => item?.id == _selectedVersionId, orElse: () => null);

  StructureOccurrenceDetailDto? get selectedOccurrence => _versionDetail
      ?.structureOccurrences
      .cast<StructureOccurrenceDetailDto?>()
      .firstWhere(
        (item) => item?.id == _selectedOccurrenceId,
        orElse: () => null,
      );

  OperationOccurrenceDetailDto? get selectedOperation => _versionDetail
      ?.operationOccurrences
      .cast<OperationOccurrenceDetailDto?>()
      .firstWhere(
        (item) => item?.id == _selectedOperationId,
        orElse: () => null,
      );

  List<OperationOccurrenceDetailDto> get selectedOccurrenceOperations {
    final occurrenceId = _selectedOccurrenceId;
    if (occurrenceId == null ||
        occurrenceId.isEmpty ||
        _versionDetail == null) {
      return const [];
    }
    return _versionDetail!.operationOccurrences
        .where((item) => item.structureOccurrenceId == occurrenceId)
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    await loadMachines();
  }

  Future<void> loadMachines() async {
    final previousMachineId = _selectedMachineId;
    final previousVersionId = _selectedVersionId;
    _isMachinesLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      final response = await client.listMachines();
      _machines
        ..clear()
        ..addAll(response.items);
      _selectedMachineId = _resolveMachineSelection(previousMachineId);
      if (_selectedMachineId == null) {
        _versions.clear();
        _resetVersionState();
      } else {
        await _loadVersions(preferredVersionId: previousVersionId);
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isMachinesLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMachine(String? machineId) async {
    _selectedMachineId = machineId;
    _versions.clear();
    _selectedVersionId = null;
    _resetVersionState();
    _clearMessages();
    notifyListeners();
    if (machineId == null || machineId.isEmpty) {
      return;
    }
    await _loadVersions();
  }

  Future<void> selectVersion(String? versionId) async {
    _selectedVersionId = versionId;
    _resetVersionState();
    _clearMessages();
    notifyListeners();
    if (versionId == null || versionId.isEmpty) {
      return;
    }
    await _loadVersionDetail();
  }

  Future<void> openMachineVersion({
    required String machineId,
    String? versionId,
  }) async {
    if (_machines.isEmpty) {
      await loadMachines();
    }
    if (_selectedMachineId != machineId || _versions.isEmpty) {
      await selectMachine(machineId);
    }
    final targetVersionId = versionId ?? _selectedVersionId;
    if (targetVersionId != null && targetVersionId.isNotEmpty) {
      await selectVersion(targetVersionId);
    }
  }

  void selectOccurrence(String? occurrenceId) {
    _selectedOccurrenceId = occurrenceId;
    final operation = selectedOperation;
    if (operation == null || operation.structureOccurrenceId != occurrenceId) {
      _selectedOperationId = null;
    }
    _clearMessages();
    notifyListeners();
  }

  void selectOperation(String? operationId) {
    _selectedOperationId = operationId;
    _clearMessages();
    notifyListeners();
  }

  Future<MachineVersionDetailDto?> createDraftFromCurrentVersion() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    if (machineId == null || versionId == null) {
      _errorMessage =
          'Select a machine version before creating an editable draft.';
      notifyListeners();
      return null;
    }
    return createDraftFromVersion(machineId: machineId, versionId: versionId);
  }

  Future<MachineVersionDetailDto?> createDraftFromVersion({
    required String machineId,
    required String versionId,
  }) async {
    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await client.createDraftMachineVersion(
        machineId,
        versionId,
        CreateDraftMachineVersionRequestDto(
          requestId: _nextRequestId('structure-draft'),
          createdBy: 'planner-1',
        ),
      );
      _successMessage = 'Editable draft ${detail.label} created.';
      await loadMachines();
      await openMachineVersion(machineId: machineId, versionId: detail.id);
      return _versionDetail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<MachineVersionDetailDto?> addStructureOccurrence({
    required String displayName,
    required String quantityPerMachine,
    String? workshop,
    String? parentOccurrenceId,
  }) async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final parsedQuantity = _parseQuantity(quantityPerMachine);
    if (machineId == null || versionId == null) {
      _errorMessage = 'Select a draft version before adding structure.';
      notifyListeners();
      return null;
    }
    if (displayName.trim().isEmpty ||
        parsedQuantity == null ||
        parsedQuantity <= 0) {
      _errorMessage =
          'Enter display name and positive quantity for the new node.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.createStructureOccurrence(
        machineId,
        versionId,
        CreateStructureOccurrenceRequestDto(
          requestId: _nextRequestId('structure-create'),
          parentOccurrenceId: parentOccurrenceId,
          displayName: displayName.trim(),
          quantityPerMachine: parsedQuantity,
          workshop: _normalizeOptional(workshop),
        ),
      ),
      successMessage: 'Structure node $displayName created.',
    );
  }

  Future<MachineVersionDetailDto?> updateSelectedOccurrence({
    required String displayName,
    required String quantityPerMachine,
    String? workshop,
  }) async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final occurrence = selectedOccurrence;
    final parsedQuantity = _parseQuantity(quantityPerMachine);
    if (machineId == null || versionId == null || occurrence == null) {
      _errorMessage = 'Select a draft occurrence before saving.';
      notifyListeners();
      return null;
    }
    if (displayName.trim().isEmpty ||
        parsedQuantity == null ||
        parsedQuantity <= 0) {
      _errorMessage = 'Enter display name and positive quantity before saving.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.updateStructureOccurrence(
        machineId,
        versionId,
        occurrence.id,
        UpdateStructureOccurrenceRequestDto(
          requestId: _nextRequestId('structure-update'),
          displayName: displayName.trim(),
          quantityPerMachine: parsedQuantity,
          workshop: _normalizeOptional(workshop),
        ),
      ),
      preserveOccurrenceId: occurrence.id,
      successMessage: 'Structure node ${occurrence.displayName} updated.',
    );
  }

  Future<MachineVersionDetailDto?> deleteSelectedOccurrence() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final occurrence = selectedOccurrence;
    if (machineId == null || versionId == null || occurrence == null) {
      _errorMessage = 'Select a draft occurrence before deleting.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.deleteStructureOccurrence(
        machineId,
        versionId,
        occurrence.id,
        DeleteStructureOccurrenceRequestDto(
          requestId: _nextRequestId('structure-delete'),
        ),
      ),
      clearOccurrenceSelection: true,
      successMessage: 'Structure node ${occurrence.displayName} deleted.',
    );
  }

  Future<MachineVersionDetailDto?> addOperation({
    required String name,
    required String quantityPerMachine,
    String? workshop,
  }) async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final occurrence = selectedOccurrence;
    final parsedQuantity = _parseQuantity(quantityPerMachine);
    if (machineId == null || versionId == null || occurrence == null) {
      _errorMessage = 'Select a draft occurrence before adding an operation.';
      notifyListeners();
      return null;
    }
    if (name.trim().isEmpty || parsedQuantity == null || parsedQuantity <= 0) {
      _errorMessage = 'Enter operation name and positive quantity.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.createOperationOccurrence(
        machineId,
        versionId,
        CreateOperationOccurrenceRequestDto(
          requestId: _nextRequestId('operation-create'),
          structureOccurrenceId: occurrence.id,
          name: name.trim(),
          quantityPerMachine: parsedQuantity,
          workshop: _normalizeOptional(workshop),
        ),
      ),
      preserveOccurrenceId: occurrence.id,
      successMessage: 'Operation $name created.',
    );
  }

  Future<MachineVersionDetailDto?> updateSelectedOperation({
    required String name,
    required String quantityPerMachine,
    String? workshop,
  }) async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final occurrence = selectedOccurrence;
    final operation = selectedOperation;
    final parsedQuantity = _parseQuantity(quantityPerMachine);
    if (machineId == null ||
        versionId == null ||
        occurrence == null ||
        operation == null) {
      _errorMessage = 'Select a draft operation before saving.';
      notifyListeners();
      return null;
    }
    if (name.trim().isEmpty || parsedQuantity == null || parsedQuantity <= 0) {
      _errorMessage = 'Enter operation name and positive quantity.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.updateOperationOccurrence(
        machineId,
        versionId,
        operation.id,
        UpdateOperationOccurrenceRequestDto(
          requestId: _nextRequestId('operation-update'),
          name: name.trim(),
          quantityPerMachine: parsedQuantity,
          workshop: _normalizeOptional(workshop),
        ),
      ),
      preserveOccurrenceId: occurrence.id,
      preserveOperationId: operation.id,
      successMessage: 'Operation ${operation.name} updated.',
    );
  }

  Future<MachineVersionDetailDto?> deleteSelectedOperation() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final occurrence = selectedOccurrence;
    final operation = selectedOperation;
    if (machineId == null ||
        versionId == null ||
        occurrence == null ||
        operation == null) {
      _errorMessage = 'Select a draft operation before deleting.';
      notifyListeners();
      return null;
    }
    return _runVersionMutation(
      () => client.deleteOperationOccurrence(
        machineId,
        versionId,
        operation.id,
        DeleteOperationOccurrenceRequestDto(
          requestId: _nextRequestId('operation-delete'),
        ),
      ),
      preserveOccurrenceId: occurrence.id,
      clearOperationSelection: true,
      successMessage: 'Operation ${operation.name} deleted.',
    );
  }

  Future<MachineVersionDetailDto?> publishCurrentVersion() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    final detail = _versionDetail;
    if (machineId == null || versionId == null || detail == null) {
      _errorMessage = 'Select a draft version before publishing.';
      notifyListeners();
      return null;
    }
    if (detail.isImmutable) {
      _errorMessage = 'Published versions are read-only. Create a draft first.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final published = await client.publishMachineVersion(
        machineId,
        versionId,
        PublishMachineVersionRequestDto(
          requestId: _nextRequestId('structure-publish'),
          publishedBy: 'planner-1',
        ),
      );
      _successMessage = 'Version ${published.label} published and activated.';
      await loadMachines();
      await openMachineVersion(machineId: machineId, versionId: published.id);
      return _versionDetail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _loadVersions({String? preferredVersionId}) async {
    final machineId = _selectedMachineId;
    if (machineId == null || machineId.isEmpty) {
      return;
    }
    _isVersionsLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      final response = await client.listMachineVersions(machineId);
      _versions
        ..clear()
        ..addAll(response.items);
      _selectedVersionId = _resolveVersionSelection(preferredVersionId);
      if (_selectedVersionId != null) {
        await _loadVersionDetail();
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isVersionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVersionDetail() async {
    final machineId = _selectedMachineId;
    final versionId = _selectedVersionId;
    if (machineId == null ||
        machineId.isEmpty ||
        versionId == null ||
        versionId.isEmpty) {
      return;
    }
    _isDetailLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await client.getMachineVersionDetail(machineId, versionId);
      _applyVersionDetail(detail);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<MachineVersionDetailDto?> _runVersionMutation(
    Future<MachineVersionDetailDto> Function() mutation, {
    String? preserveOccurrenceId,
    String? preserveOperationId,
    bool clearOccurrenceSelection = false,
    bool clearOperationSelection = false,
    required String successMessage,
  }) async {
    _isSaving = true;
    _clearMessages();
    notifyListeners();

    try {
      final detail = await mutation();
      _applyVersionDetail(
        detail,
        preferredOccurrenceId: clearOccurrenceSelection
            ? null
            : preserveOccurrenceId,
        preferredOperationId: clearOperationSelection
            ? null
            : preserveOperationId,
      );
      _successMessage = successMessage;
      return detail;
    } catch (error) {
      _errorMessage = _describeError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _applyVersionDetail(
    MachineVersionDetailDto detail, {
    String? preferredOccurrenceId,
    String? preferredOperationId,
  }) {
    _versionDetail = detail;
    _selectedVersionId = detail.id;
    _rebuildTree(detail.structureOccurrences);
    final nextOccurrenceId =
        preferredOccurrenceId != null &&
            detail.structureOccurrences.any(
              (item) => item.id == preferredOccurrenceId,
            )
        ? preferredOccurrenceId
        : detail.structureOccurrences.isNotEmpty
        ? detail.structureOccurrences.first.id
        : null;
    _selectedOccurrenceId = nextOccurrenceId;
    if (nextOccurrenceId == null) {
      _selectedOperationId = null;
      return;
    }
    final operations = detail.operationOccurrences
        .where((item) => item.structureOccurrenceId == nextOccurrenceId)
        .toList(growable: false);
    _selectedOperationId =
        preferredOperationId != null &&
            operations.any((item) => item.id == preferredOperationId)
        ? preferredOperationId
        : operations.isNotEmpty
        ? operations.first.id
        : null;
  }

  void _rebuildTree(List<StructureOccurrenceDetailDto> occurrences) {
    _nodeIndex.clear();
    _treeRoot = null;
    if (occurrences.isEmpty) {
      return;
    }
    final byParent = <String?, List<StructureOccurrenceDetailDto>>{};
    for (final occurrence in occurrences) {
      byParent
          .putIfAbsent(occurrence.parentOccurrenceId, () => [])
          .add(occurrence);
    }

    List<StructureTreeNode> buildChildren(String? parentId, int depth) {
      final children = [
        ...(byParent[parentId] ?? const <StructureOccurrenceDetailDto>[]),
      ];
      children.sort((left, right) => left.pathKey.compareTo(right.pathKey));
      return children
          .map(
            (occurrence) => StructureTreeNode(
              occurrence: occurrence,
              depth: depth,
              children: buildChildren(occurrence.id, depth + 1),
            ),
          )
          .toList(growable: false);
    }

    final children = buildChildren(null, 0);
    _treeRoot = StructureTreeNode.root(children: children);
    void indexNodes(StructureTreeNode node) {
      if (node.occurrence != null) {
        _nodeIndex[node.occurrence!.id] = node;
      }
      for (final child in node.children) {
        indexNodes(child);
      }
    }

    indexNodes(_treeRoot!);
  }

  String? _resolveMachineSelection(String? preferredMachineId) {
    if (_machines.isEmpty) {
      return null;
    }
    if (preferredMachineId != null &&
        _machines.any((item) => item.id == preferredMachineId)) {
      return preferredMachineId;
    }
    return _machines.first.id;
  }

  String? _resolveVersionSelection(String? preferredVersionId) {
    if (_versions.isEmpty) {
      return null;
    }
    if (preferredVersionId != null &&
        _versions.any((item) => item.id == preferredVersionId)) {
      return preferredVersionId;
    }
    final activeVersionId = selectedMachine?.activeVersionId;
    if (activeVersionId != null &&
        _versions.any((item) => item.id == activeVersionId)) {
      return activeVersionId;
    }
    return _versions.first.id;
  }

  void _resetVersionState() {
    _versionDetail = null;
    _treeRoot = null;
    _nodeIndex.clear();
    _selectedOccurrenceId = null;
    _selectedOperationId = null;
  }

  String _nextRequestId(String prefix) {
    _requestSequence += 1;
    return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }

  double? _parseQuantity(String rawValue) {
    return double.tryParse(rawValue.replaceAll(',', '.'));
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}

class StructureTreeNode {
  const StructureTreeNode({
    required this.occurrence,
    required this.depth,
    required this.children,
  }) : isRoot = false;

  const StructureTreeNode.root({required this.children})
    : occurrence = null,
      depth = -1,
      isRoot = true;

  final StructureOccurrenceDetailDto? occurrence;
  final int depth;
  final List<StructureTreeNode> children;
  final bool isRoot;

  String get id => occurrence?.id ?? 'root';
  String get label => occurrence?.displayName ?? 'Whole machine';
}
