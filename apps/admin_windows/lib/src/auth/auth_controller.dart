import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../import/admin_backend_client.dart';
import 'auth_session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.client,
    LoginResponseDto? initialSession,
    AuthSessionStore? sessionStore,
  }) : _session = initialSession,
       _sessionStore = sessionStore ?? AuthSessionStore() {
    if (initialSession != null) {
      if (client is SessionAwareAdminBackendClient) {
        (client as SessionAwareAdminBackendClient).restoreSession(
          initialSession,
        );
      }
    }
  }

  final AdminBackendClient client;
  final AuthSessionStore _sessionStore;

  LoginResponseDto? _session;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isRestoring = false;

  bool get isAuthenticated => _session != null;
  String? get token => _session?.token;
  String? get userId => _session?.userId;
  String? get role => _session?.role;
  String? get displayName => _session?.displayName;
  DateTime? get expiresAt => _session?.expiresAt;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isRestoring => _isRestoring;

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final session = await _sessionStore.load();
      _session = session;
      if (session != null) {
        if (client is SessionAwareAdminBackendClient) {
          (client as SessionAwareAdminBackendClient).restoreSession(session);
        }
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String login, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await client.login(
        LoginRequestDto(login: login.trim(), password: password),
      );
      await _sessionStore.save(_session!);
      return true;
    } catch (error) {
      _errorMessage = _describeError(error);
      _session = null;
      await _sessionStore.clear();
      if (client case final SessionAwareAdminBackendClient c) {
        c.clearSession();
      }
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
      await _sessionStore.clear();
      if (client case final SessionAwareAdminBackendClient c) {
        c.clearSession();
      }
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
    return 'Непредвиденная ошибка: $error';
  }
}
