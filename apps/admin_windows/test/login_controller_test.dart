import 'package:admin_windows/src/auth/auth_controller.dart';
import 'package:admin_windows/src/auth/auth_session_store.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthController', () {
    test('successful login stores authenticated session', () async {
      final controller = AuthController(client: _FakeAuthBackendClient());

      final success = await controller.login(
        login: 'planner-1',
        password: 'planner123',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.userId, 'planner-1');
      expect(controller.role, 'planner');
      expect(controller.errorMessage, isNull);
    });

    test('invalid credentials expose error message', () async {
      final controller = AuthController(
        client: _FakeAuthBackendClient(
          error: const AdminBackendException(
            code: 'invalid_credentials',
            message: 'Invalid credentials.',
            statusCode: 401,
          ),
        ),
      );

      final success = await controller.login(
        login: 'planner-1',
        password: 'wrong',
      );

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, 'Invalid credentials.');
    });

    test('disabled account remains logged out', () async {
      final controller = AuthController(
        client: _FakeAuthBackendClient(
          error: const AdminBackendException(
            code: 'account_disabled',
            message: 'Account is disabled.',
            statusCode: 403,
          ),
        ),
      );

      await controller.login(login: 'master-2', password: 'master999');

      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, 'Account is disabled.');
    });

    test('restores persisted session on startup', () async {
      final sessionStore = _FakeAuthSessionStore(
        session: LoginResponseDto(
          token: 'token-restore',
          userId: 'planner-1',
          role: 'planner',
          displayName: 'Planner One',
          expiresAt: DateTime.utc(2026, 4, 5, 12),
        ),
      );
      final client = _FakeAuthBackendClient();
      final controller = AuthController(
        client: client,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.userId, 'planner-1');
      expect(client.restoredToken, 'token-restore');
    });

    test('logout clears persisted session', () async {
      final sessionStore = _FakeAuthSessionStore();
      final controller = AuthController(
        client: _FakeAuthBackendClient(),
        initialSession: LoginResponseDto(
          token: 'token-1',
          userId: 'planner-1',
          role: 'planner',
          displayName: 'Planner One',
          expiresAt: DateTime.utc(2026, 4, 5, 12),
        ),
        sessionStore: sessionStore,
      );

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(sessionStore.wasCleared, isTrue);
    });
  });
}

class _FakeAuthBackendClient
    implements AdminBackendClient, SessionAwareAdminBackendClient {
  _FakeAuthBackendClient({this.error});

  final AdminBackendException? error;
  String? restoredToken;
  bool sessionCleared = false;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    if (error != null) {
      throw error!;
    }
    return LoginResponseDto(
      token: 'token-1',
      userId: request.login,
      role: 'planner',
      displayName: 'Planner One',
      expiresAt: DateTime.utc(2026, 4, 2, 16),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  void restoreSession(LoginResponseDto session) {
    restoredToken = session.token;
  }

  @override
  void clearSession() {
    sessionCleared = true;
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuthSessionStore extends AuthSessionStore {
  _FakeAuthSessionStore({this.session});

  LoginResponseDto? session;
  bool wasCleared = false;

  @override
  Future<LoginResponseDto?> load() async => session;

  @override
  Future<void> save(LoginResponseDto session) async {
    this.session = session;
  }

  @override
  Future<void> clear() async {
    wasCleared = true;
    session = null;
  }
}
