import 'package:data_models/data_models.dart';
import 'package:flutter/foundation.dart';

import '../master/master_backend_client.dart';
import 'master_session_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required MasterBackendClient client,
    required MasterSessionRepository sessionRepository,
    LoginResponseDto? initialSession,
  }) : _client = client,
       _sessionRepository = sessionRepository,
       _session = initialSession;

  final MasterBackendClient _client;
  final MasterSessionRepository _sessionRepository;

  bool _bootstrapped = false;
  String? _errorMessage;
  bool _isBootstrapping = false;
  bool _isSubmitting = false;
  LoginResponseDto? _session;

  String? get displayName => _session?.displayName;
  String? get errorMessage => _errorMessage;
  DateTime? get expiresAt => _session?.expiresAt;
  bool get isAuthenticated => _session != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isSubmitting => _isSubmitting;
  String? get role => _session?.role;
  LoginResponseDto? get session => _session;
  String? get token => _session?.token;
  String? get userId => _session?.userId;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    _isBootstrapping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final persistedSession = _session ?? await _sessionRepository.loadSession();
      if (persistedSession == null) {
        _client.setAuthToken(null);
        return;
      }
      if (_isExpired(persistedSession)) {
        await _sessionRepository.clearSession();
        _client.setAuthToken(null);
        return;
      }
      if (persistedSession.role != 'master') {
        await _sessionRepository.clearSession();
        _client.setAuthToken(null);
        _errorMessage = 'Вход разрешён только пользователю с ролью мастера.';
        return;
      }
      _session = persistedSession;
      _client.setAuthToken(persistedSession.token);
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> expireSession([
    String message = 'Сессия истекла. Войдите снова.',
  ]) async {
    _session = null;
    _errorMessage = message;
    _client.setAuthToken(null);
    await _sessionRepository.clearSession();
    notifyListeners();
  }

  Future<bool> login({required String login, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextSession = await _client.login(
        LoginRequestDto(login: login.trim(), password: password),
      );
      if (nextSession.role != 'master') {
        _client.setAuthToken(null);
        _session = null;
        _errorMessage = 'Вход разрешён только пользователю с ролью мастера.';
        return false;
      }
      _session = nextSession;
      await _sessionRepository.saveSession(nextSession);
      return true;
    } catch (error) {
      _session = null;
      _client.setAuthToken(null);
      _errorMessage = _describeError(error);
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
      await _client.logout();
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _session = null;
      _client.setAuthToken(null);
      await _sessionRepository.clearSession();
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _describeError(Object error) {
    if (error is MasterBackendException) {
      return error.message;
    }
    return 'Непредвиденная ошибка: $error';
  }

  bool _isExpired(LoginResponseDto session) {
    return !session.expiresAt.isAfter(DateTime.now().toUtc());
  }
}
