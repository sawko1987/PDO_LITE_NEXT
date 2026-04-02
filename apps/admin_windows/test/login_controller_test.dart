import 'package:admin_windows/src/auth/auth_controller.dart';
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
  });
}

class _FakeAuthBackendClient implements AdminBackendClient {
  _FakeAuthBackendClient({this.error});

  final AdminBackendException? error;

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
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
