import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/src/auth/auth_controller.dart';
import 'package:master_mobile/src/auth/master_session_repository.dart';
import 'package:master_mobile/src/master/master_backend_client.dart';

void main() {
  group('AuthController', () {
    test('successful login stores session and token', () async {
      final client = _FakeAuthBackendClient();
      final repository = _MemorySessionRepository();
      final controller = AuthController(
        client: client,
        sessionRepository: repository,
      );

      final result = await controller.login(
        login: 'master-1',
        password: 'master123',
      );

      expect(result, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.userId, 'master-1');
      expect(client.authToken, 'token-master-1');
      expect((await repository.loadSession())?.userId, 'master-1');
    });

    test('bootstrap restores persisted master session', () async {
      final client = _FakeAuthBackendClient();
      final repository = _MemorySessionRepository(
        session: LoginResponseDto(
          token: 'persisted-token',
          userId: 'master-1',
          role: 'master',
          displayName: 'Master One',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
        ),
      );
      final controller = AuthController(
        client: client,
        sessionRepository: repository,
      );

      await controller.bootstrap();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.userId, 'master-1');
      expect(client.authToken, 'persisted-token');
    });

    test('bootstrap clears expired session', () async {
      final client = _FakeAuthBackendClient();
      final repository = _MemorySessionRepository(
        session: LoginResponseDto(
          token: 'expired-token',
          userId: 'master-1',
          role: 'master',
          displayName: 'Master One',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        ),
      );
      final controller = AuthController(
        client: client,
        sessionRepository: repository,
      );

      await controller.bootstrap();

      expect(controller.isAuthenticated, isFalse);
      expect(await repository.loadSession(), isNull);
      expect(client.authToken, isNull);
    });

    test('rejects login for non-master role', () async {
      final controller = AuthController(
        client: _FakeAuthBackendClient(role: 'planner'),
        sessionRepository: _MemorySessionRepository(),
      );

      final result = await controller.login(
        login: 'planner-1',
        password: 'planner123',
      );

      expect(result, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(
        controller.errorMessage,
        'Вход разрешён только пользователю с ролью мастера.',
      );
    });

    test('expireSession clears persisted state', () async {
      final client = _FakeAuthBackendClient();
      final repository = _MemorySessionRepository();
      final controller = AuthController(
        client: client,
        sessionRepository: repository,
      );

      await controller.login(login: 'master-1', password: 'master123');
      await controller.expireSession();

      expect(controller.isAuthenticated, isFalse);
      expect(await repository.loadSession(), isNull);
      expect(client.authToken, isNull);
      expect(controller.errorMessage, 'Сессия истекла. Войдите снова.');
    });
  });
}

class _FakeAuthBackendClient implements MasterBackendClient {
  _FakeAuthBackendClient({this.role = 'master'});

  String? authToken;
  final String role;

  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  Future<ProblemDetailDto> getProblem(String problemId) {
    throw UnimplementedError();
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listReports(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({
    String? assigneeId,
    String? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    authToken = 'token-${request.login}';
    return LoginResponseDto(
      token: authToken!,
      userId: request.login,
      role: role,
      displayName: 'User ${request.login}',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
    );
  }

  @override
  Future<void> logout() async {
    authToken = null;
  }

  @override
  void setAuthToken(String? token) {
    authToken = token;
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) {
    throw UnimplementedError();
  }
}

class _MemorySessionRepository implements MasterSessionRepository {
  _MemorySessionRepository({LoginResponseDto? session}) : _session = session;

  LoginResponseDto? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<LoginResponseDto?> loadSession() async => _session;

  @override
  Future<void> saveSession(LoginResponseDto session) async {
    _session = session;
  }
}
