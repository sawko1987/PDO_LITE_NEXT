import 'dart:convert';
import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import 'admin_backend_client.dart';

enum ImportConfirmMode {
  createMachine('create_machine'),
  createVersion('create_version');

  const ImportConfirmMode(this.apiValue);

  final String apiValue;
}

class ImportFlowController extends ChangeNotifier {
  ImportFlowController({required this.client});

  final AdminBackendClient client;

  final List<MachineSummaryDto> _machines = [];
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  ImportSessionSummaryDto? _session;
  ConfirmImportResultDto? _confirmResult;
  String? _targetMachineId;
  String? _errorMessage;
  ImportConfirmMode _confirmMode = ImportConfirmMode.createMachine;
  bool _isMachinesLoading = false;
  bool _isPreviewLoading = false;
  bool _isConfirming = false;
  int _requestSequence = 0;

  List<MachineSummaryDto> get machines => List.unmodifiable(_machines);
  String? get selectedFileName => _selectedFileName;
  ImportSessionSummaryDto? get session => _session;
  ConfirmImportResultDto? get confirmResult => _confirmResult;
  String? get targetMachineId => _targetMachineId;
  String? get errorMessage => _errorMessage;
  ImportConfirmMode get confirmMode => _confirmMode;
  bool get isMachinesLoading => _isMachinesLoading;
  bool get isPreviewLoading => _isPreviewLoading;
  bool get isConfirming => _isConfirming;
  bool get isBusy => _isMachinesLoading || _isPreviewLoading || _isConfirming;

  bool get canBuildPreview =>
      !_isPreviewLoading &&
      !_isConfirming &&
      _selectedFileName != null &&
      _selectedFileBytes != null;

  bool get canConfirm {
    final preview = _session?.preview;
    if (preview == null ||
        !preview.canConfirm ||
        _isConfirming ||
        _isPreviewLoading) {
      return false;
    }

    if (_confirmMode == ImportConfirmMode.createVersion &&
        (_targetMachineId == null || _targetMachineId!.isEmpty)) {
      return false;
    }

    return true;
  }

  Future<void> bootstrap() async {
    await loadMachines();
  }

  void setSelectedFile({required String fileName, required Uint8List bytes}) {
    _selectedFileName = fileName;
    _selectedFileBytes = bytes;
    _confirmResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setConfirmMode(ImportConfirmMode mode) {
    _confirmMode = mode;
    if (mode == ImportConfirmMode.createMachine) {
      _targetMachineId = null;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void selectTargetMachine(String? machineId) {
    _targetMachineId = machineId;
    _errorMessage = null;
    notifyListeners();
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
      if (_targetMachineId != null &&
          !_machines.any((machine) => machine.id == _targetMachineId)) {
        _targetMachineId = null;
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isMachinesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPreview() async {
    final fileName = _selectedFileName;
    final fileBytes = _selectedFileBytes;
    if (fileName == null || fileBytes == null) {
      _errorMessage = 'Select an Excel or MXL file before building preview.';
      notifyListeners();
      return;
    }

    _isPreviewLoading = true;
    _confirmResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final preview = await client.createImportPreview(
        CreateImportPreviewRequestDto(
          requestId: _nextRequestId('preview'),
          fileName: fileName,
          fileContentBase64: base64Encode(fileBytes),
        ),
      );
      _session = preview;
      if (_confirmMode == ImportConfirmMode.createVersion &&
          !_machines.any((machine) => machine.id == _targetMachineId)) {
        _targetMachineId = null;
      }
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    final sessionId = _session?.sessionId;
    if (sessionId == null) {
      return;
    }

    _isPreviewLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await client.getImportSession(sessionId);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmImport() async {
    final session = _session;
    if (session == null) {
      _errorMessage = 'Build preview before confirming import.';
      notifyListeners();
      return;
    }
    if (!canConfirm) {
      _errorMessage = _confirmMode == ImportConfirmMode.createVersion
          ? 'Select target machine before creating a new version.'
          : 'Current preview cannot be confirmed.';
      notifyListeners();
      return;
    }

    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _confirmResult = await client.confirmImport(
        session.sessionId,
        ConfirmImportRequestDto(
          requestId: _nextRequestId('confirm'),
          mode: _confirmMode.apiValue,
          targetMachineId: _confirmMode == ImportConfirmMode.createVersion
              ? _targetMachineId
              : null,
        ),
      );
      _session = await client.getImportSession(session.sessionId);
      final refreshedMachines = await client.listMachines();
      _machines
        ..clear()
        ..addAll(refreshedMachines.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isConfirming = false;
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
