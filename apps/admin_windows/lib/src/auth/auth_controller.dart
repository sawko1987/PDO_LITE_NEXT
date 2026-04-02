import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';

class AuthController extends ChangeNotifier {
  AuthController({required this.client, LoginResponseDto? initialSession})
    : _session = initialSession;

  final AdminBackendClient client;

  LoginResponseDto? _session;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool get isAuthenticated => _session != null;
  String? get token => _session?.token;
  String? get userId => _session?.userId;
  String? get role => _session?.role;
  String? get displayName => _session?.displayName;
  DateTime? get expiresAt => _session?.expiresAt;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  Future<bool> login({required String login, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await client.login(
        LoginRequestDto(login: login.trim(), password: password),
      );
      return true;
    } catch (error) {
      _errorMessage = _describeError(error);
      _session = null;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await client.logout();
      _session = null;
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _describeError(Object error) {
    if (error is AdminBackendException) {
      return error.message;
    }
    return 'Unexpected error: $error';
  }
}
