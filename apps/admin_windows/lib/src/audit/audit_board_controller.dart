import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class AuditBoardController extends ChangeNotifier {
  AuditBoardController({required this.client});

  final AdminBackendClient client;

  final List<AuditEntryDto> _entries = [];
  final List<UserSummaryDto> _users = [];
  String? _entityType;
  String? _entityId;
  String? _action;
  String? _changedBy;
  String? _fromDate;
  String? _toDate;
  int _limit = 100;
  int _offset = 0;
  int? _total;
  bool _isLoading = false;
  String? _errorMessage;

  List<AuditEntryDto> get entries => List.unmodifiable(_entries);
  List<UserSummaryDto> get users => List.unmodifiable(_users);
  String? get entityType => _entityType;
  String? get entityId => _entityId;
  String? get action => _action;
  String? get changedBy => _changedBy;
  String? get fromDate => _fromDate;
  String? get toDate => _toDate;
  int get limit => _limit;
  int get offset => _offset;
  int? get total => _total;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    await Future.wait([loadUsers(), loadAudit()]);
  }

  Future<void> loadUsers() async {
    try {
      final response = await client.listUsers();
      _users
        ..clear()
        ..addAll(response.items);
      notifyListeners();
    } catch (_) {
      // Audit should still work even if users list is unavailable.
    }
  }

  Future<void> loadAudit({
    String? entityType,
    String? entityId,
    String? action,
    String? changedBy,
    String? fromDate,
    String? toDate,
    int? limit,
    int? offset,
  }) async {
    if (entityType != null) {
      _entityType = _normalize(entityType);
    }
    if (entityId != null) {
      _entityId = _normalize(entityId);
    }
    if (action != null) {
      _action = _normalize(action);
    }
    if (changedBy != null) {
      _changedBy = _normalize(changedBy);
    }
    if (fromDate != null) {
      _fromDate = _normalize(fromDate);
    }
    if (toDate != null) {
      _toDate = _normalize(toDate);
    }
    if (limit != null) {
      _limit = limit;
    }
    if (offset != null) {
      _offset = offset;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listAuditEntries(
        entityType: _entityType,
        entityId: _entityId,
        action: _action,
        changedBy: _changedBy,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: _limit,
        offset: _offset,
      );
      _entries
        ..clear()
        ..addAll(response.items);
      _total = response.total;
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String buildCsv() {
    const header =
        'changedAt,changedBy,entityType,entityId,action,field,beforeValue,afterValue';
    final lines = _entries.map((entry) {
      return [
        entry.changedAt.toIso8601String(),
        entry.changedBy,
        entry.entityType,
        entry.entityId,
        entry.action,
        entry.field ?? '',
        entry.beforeValue ?? '',
        entry.afterValue ?? '',
      ].map(_escapeCsv).join(',');
    });
    return ([header, ...lines]).join('\n');
  }

  void setEntityType(String? value) {
    _entityType = _normalize(value);
    notifyListeners();
  }

  void setEntityId(String? value) {
    _entityId = _normalize(value);
    notifyListeners();
  }

  void setAction(String? value) {
    _action = _normalize(value);
    notifyListeners();
  }

  void setChangedBy(String? value) {
    _changedBy = _normalize(value);
    notifyListeners();
  }

  void setDateRange(String? fromDate, String? toDate) {
    _fromDate = _normalize(fromDate);
    _toDate = _normalize(toDate);
    notifyListeners();
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _escapeCsv(String value) {
    final normalized = value.replaceAll('"', '""');
    return '"$normalized"';
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Непредвиденная ошибка: $error';
  }
}
