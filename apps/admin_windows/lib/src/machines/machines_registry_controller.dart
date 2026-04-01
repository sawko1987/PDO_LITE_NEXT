import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class MachinesRegistryController extends ChangeNotifier {
  MachinesRegistryController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  final List<MachineVersionSummaryDto> _versions = [];
  final List<PlanningSourceOccurrenceDto> _planningSource = [];
  final Map<String, MachineVersionTreeNode> _treeNodeIndex = {};
  String? _selectedMachineId;
  String? _selectedVersionId;
  MachineVersionTreeNode? _planningTreeRoot;
  String? _errorMessage;
  bool _isMachinesLoading = false;
  bool _isVersionsLoading = false;
  bool _isPlanningSourceLoading = false;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  List<MachineVersionSummaryDto> get versions => List.unmodifiable(_versions);
  List<PlanningSourceOccurrenceDto> get planningSource =>
      List.unmodifiable(_planningSource);
  String? get selectedMachineId => _selectedMachineId;
  String? get selectedVersionId => _selectedVersionId;
  MachineSummaryDto? get selectedMachine => _machines
      .cast<MachineSummaryDto?>()
      .firstWhere((item) => item?.id == _selectedMachineId, orElse: () => null);
  MachineVersionSummaryDto? get selectedVersion => _versions
      .cast<MachineVersionSummaryDto?>()
      .firstWhere((item) => item?.id == _selectedVersionId, orElse: () => null);
  MachineVersionTreeNode? get planningTreeRoot => _planningTreeRoot;
  String? get errorMessage => _errorMessage;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isVersionsLoading => _isVersionsLoading;
  bool get isPlanningSourceLoading => _isPlanningSourceLoading;
  bool get isBusy =>
      _isMachinesLoading || _isVersionsLoading || _isPlanningSourceLoading;

  int get selectedVersionOccurrenceCount => _planningSource.length;
  int get selectedVersionOperationCount =>
      _planningSource.fold(0, (sum, item) => sum + item.operationCount);
  int get selectedMachineVersionCount => _versions.length;
  bool get selectedVersionIsActive =>
      selectedMachine?.activeVersionId == selectedVersion?.id;

  Future<void> bootstrap() async {
    await loadMachines();
  }

  Future<void> loadMachines() async {
    final previousMachineId = _selectedMachineId;
    final previousVersionId = _selectedVersionId;

    _isMachinesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listMachines();
      _machines
        ..clear()
        ..addAll(response.items);

      final nextMachineId = _resolveMachineSelection(previousMachineId);
      _selectedMachineId = nextMachineId;
      if (nextMachineId == null) {
        _versions.clear();
        _planningSource.clear();
        _rebuildTree();
      } else {
        await _loadVersions(
          machineId: nextMachineId,
          preferredVersionId: previousVersionId,
        );
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isMachinesLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMachine(String? machineId) async {
    if (machineId == null || machineId.isEmpty) {
      _selectedMachineId = null;
      _selectedVersionId = null;
      _versions.clear();
      _planningSource.clear();
      _rebuildTree();
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _selectedMachineId = machineId;
    _selectedVersionId = null;
    _versions.clear();
    _planningSource.clear();
    _rebuildTree();
    _errorMessage = null;
    notifyListeners();

    await _loadVersions(machineId: machineId);
  }

  Future<void> selectVersion(String? versionId) async {
    if (versionId == null || versionId.isEmpty) {
      _selectedVersionId = null;
      _planningSource.clear();
      _rebuildTree();
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _selectedVersionId = versionId;
    _planningSource.clear();
    _rebuildTree();
    _errorMessage = null;
    notifyListeners();
    await _loadPlanningSource();
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
      await _loadVersions(
        machineId: machineId,
        preferredVersionId: _selectedVersionId,
      );
    }

    if (versionId != null &&
        versionId.isNotEmpty &&
        _selectedVersionId != versionId) {
      await selectVersion(versionId);
    }
  }

  Future<void> _loadVersions({
    required String machineId,
    String? preferredVersionId,
  }) async {
    _isVersionsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listMachineVersions(machineId);
      _versions
        ..clear()
        ..addAll(response.items);
      final nextVersionId = _resolveVersionSelection(
        preferredVersionId: preferredVersionId,
      );
      _selectedVersionId = nextVersionId;
      if (nextVersionId == null) {
        _planningSource.clear();
        _rebuildTree();
      } else {
        await _loadPlanningSource();
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isVersionsLoading = false;
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
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listPlanningSource(machineId, versionId);
      _planningSource
        ..clear()
        ..addAll(response.items);
      _rebuildTree();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPlanningSourceLoading = false;
      notifyListeners();
    }
  }

  void _rebuildTree() {
    _treeNodeIndex.clear();
    _planningTreeRoot = null;
    if (_planningSource.isEmpty) {
      return;
    }

    final rootBuilder = _MutableMachineVersionTreeNode(
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
          () => _MutableMachineVersionTreeNode(
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
            () => _MutableMachineVersionTreeNode(
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
          () => _MutableMachineVersionTreeNode(
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

    _planningTreeRoot = _freezeTree(rootBuilder, depth: 0);
  }

  MachineVersionTreeNode _freezeTree(
    _MutableMachineVersionTreeNode builder, {
    required int depth,
  }) {
    final children =
        builder.children.values
            .map((child) => _freezeTree(child, depth: depth + 1))
            .toList(growable: false)
          ..sort((left, right) {
            if (left.isLeaf != right.isLeaf) {
              return left.isLeaf ? 1 : -1;
            }
            return left.label.toLowerCase().compareTo(
              right.label.toLowerCase(),
            );
          });

    final node = MachineVersionTreeNode(
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
    _treeNodeIndex[node.id] = node;
    return node;
  }

  String? _resolveMachineSelection(String? preferredMachineId) {
    if (_machines.isEmpty) {
      return null;
    }
    if (preferredMachineId != null &&
        _machines.any((machine) => machine.id == preferredMachineId)) {
      return preferredMachineId;
    }
    return _machines.first.id;
  }

  String? _resolveVersionSelection({String? preferredVersionId}) {
    if (_versions.isEmpty) {
      return null;
    }
    if (preferredVersionId != null &&
        _versions.any((version) => version.id == preferredVersionId)) {
      return preferredVersionId;
    }
    final activeVersionId = selectedMachine?.activeVersionId;
    if (activeVersionId != null &&
        _versions.any((version) => version.id == activeVersionId)) {
      return activeVersionId;
    }
    return _versions.first.id;
  }

  String _resolveRootLabel() {
    final machine = selectedMachine;
    if (machine == null) {
      return 'Whole machine';
    }
    return 'Whole machine: ${machine.code}';
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}

class MachineVersionTreeNode {
  const MachineVersionTreeNode({
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
  final List<MachineVersionTreeNode> children;
  final PlanningSourceOccurrenceDto? occurrence;

  bool get isLeaf => occurrence != null;
}

class _MutableMachineVersionTreeNode {
  _MutableMachineVersionTreeNode({
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
  final Map<String, _MutableMachineVersionTreeNode> children = {};
  final PlanningSourceOccurrenceDto? occurrence;
}
