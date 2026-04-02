import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class BackupController extends ChangeNotifier {
  BackupController({required this.client, required this.currentUserId});

  final AdminBackendClient client;
  final String currentUserId;

  final List<BackupInfoDto> _backups = [];
  HealthExtendedDto? _health;
  IdempotencyStatsDto? _idempotencyStats;
  bool _isDiagnosticsLoading = false;
  bool _isBackupsLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  int _requestSequence = 0;

  List<BackupInfoDto> get backups => List.unmodifiable(_backups);
  HealthExtendedDto? get health => _health;
  IdempotencyStatsDto? get idempotencyStats => _idempotencyStats;
  bool get isDiagnosticsLoading => _isDiagnosticsLoading;
  bool get isBackupsLoading => _isBackupsLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isDiagnosticsLoading || _isBackupsLoading || _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> bootstrap() async {
    await Future.wait([loadDiagnostics(), loadBackups()]);
  }

  Future<void> loadDiagnostics() async {
    _isDiagnosticsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        client.getHealthExtended(),
        client.getIdempotencyStats(),
      ]);
      _health = results[0] as HealthExtendedDto;
      _idempotencyStats = results[1] as IdempotencyStatsDto;
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isDiagnosticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBackups() async {
    _isBackupsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listBackups();
      _backups
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isBackupsLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBackup() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final backup = await client.createBackup(
        CreateBackupRequestDto(
          requestId: _nextRequestId('create-backup'),
          createdBy: currentUserId,
        ),
      );
      _backups.insert(0, backup);
      _successMessage = 'Backup ${backup.fileName} was created.';
      await loadDiagnostics();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> restoreBackup(String backupFileName) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await client.restoreBackup(
        RestoreBackupRequestDto(
          requestId: _nextRequestId('restore-backup'),
          backupFileName: backupFileName,
        ),
      );
      _successMessage =
          'Backup $backupFileName was restored at ${result.restoredAt.toIso8601String()}.';
      await Future.wait([loadDiagnostics(), loadBackups()]);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSaving = false;
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
    return 'Unexpected error: $error';
  }
}
