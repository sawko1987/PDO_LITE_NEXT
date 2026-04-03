import 'dart:convert';
import 'dart:typed_data';

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
  bool get hasSelectedFile =>
      _selectedFileName != null && _selectedFileBytes != null;

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
    _session = null;
    _confirmResult = null;
    _errorMessage = null;
    debugPrint('[import] selected file: $fileName (${bytes.length} bytes)');
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

  void prepareCreateVersion(String machineId) {
    _confirmMode = ImportConfirmMode.createVersion;
    _targetMachineId = machineId;
    _confirmResult = null;
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
      _errorMessage = 'Выберите файл Excel или MXL перед предпросмотром.';
      debugPrint('[import] preview blocked: no file selected');
      notifyListeners();
      return;
    }

    _isPreviewLoading = true;
    _confirmResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[import] building preview for $fileName');
      final preview = await client.createImportPreview(
        CreateImportPreviewRequestDto(
          requestId: _nextRequestId('preview'),
          fileName: fileName,
          fileContentBase64: base64Encode(fileBytes),
        ),
      );
      _session = preview;
      debugPrint(
        '[import] preview ready: session=${preview.sessionId}, canConfirm=${preview.preview.canConfirm}, conflicts=${preview.preview.conflictCount}, warnings=${preview.preview.warningCount}',
      );
      if (_confirmMode == ImportConfirmMode.createVersion &&
          !_machines.any((machine) => machine.id == _targetMachineId)) {
        _targetMachineId = null;
      }
    } catch (error) {
      _errorMessage = _describeError(error);
      debugPrint('[import] preview failed: $_errorMessage');
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
      debugPrint('[import] session refreshed: $sessionId');
    } catch (error) {
      _errorMessage = _describeError(error);
      debugPrint('[import] refresh failed: $_errorMessage');
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmImport() async {
    final session = _session;
    if (session == null) {
      _errorMessage = 'Сначала сформируйте предпросмотр.';
      debugPrint('[import] confirm blocked: preview not built');
      notifyListeners();
      return;
    }

    if (!canConfirm) {
      _errorMessage = _confirmMode == ImportConfirmMode.createVersion
          ? 'Выберите целевое оборудование для новой версии.'
          : 'Текущий предпросмотр нельзя подтвердить.';
      debugPrint('[import] confirm blocked: $_errorMessage');
      notifyListeners();
      return;
    }

    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(
        '[import] confirming session=${session.sessionId}, mode=${_confirmMode.apiValue}, targetMachineId=$_targetMachineId',
      );
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
      debugPrint(
        '[import] confirm completed: machine=${_confirmResult?.machineId}, version=${_confirmResult?.versionId}',
      );
    } catch (error) {
      _errorMessage = _describeError(error);
      debugPrint('[import] confirm failed: $_errorMessage');
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }

  String _nextRequestId(String prefix) {
    _requestSequence += 1;
    return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }

    return 'Непредвиденная ошибка: $error';
  }
}
