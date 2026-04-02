import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class UsersBoardController extends ChangeNotifier {
  UsersBoardController({required this.client});

  final AdminBackendClient client;

  final List<UserSummaryDto> _users = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  int _requestSequence = 0;

  List<UserSummaryDto> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> bootstrap() => loadUsers();

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.listUsers();
      _users
        ..clear()
        ..addAll(response.items);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String login,
    required String password,
    required String role,
    required String displayName,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await client.createUser(
        CreateUserRequestDto(
          requestId: _nextRequestId('create-user'),
          login: login.trim(),
          password: password,
          role: role,
          displayName: displayName.trim(),
        ),
      );
      _users.removeWhere((item) => item.id == user.id);
      _users.add(user);
      _users.sort((left, right) => left.login.compareTo(right.login));
      _successMessage = 'User ${user.login} was created.';
      return true;
    } catch (error) {
      _errorMessage = _describeError(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deactivateUser(String userId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await client.deactivateUser(
        userId,
        RequestIdDto(requestId: _nextRequestId('deactivate-user')),
      );
      _replaceUser(user);
      _successMessage = 'User ${user.login} was deactivated.';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await client.resetUserPassword(
        userId,
        ResetPasswordRequestDto(
          requestId: _nextRequestId('reset-user-password'),
          newPassword: newPassword,
        ),
      );
      _replaceUser(user);
      _successMessage = 'Password was reset for ${user.login}.';
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _replaceUser(UserSummaryDto user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
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
