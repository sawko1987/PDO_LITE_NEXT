import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/users/users_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsersBoardController', () {
    test(
      'bootstrap loads users and create/deactivate/reset update state',
      () async {
        final controller = UsersBoardController(
          client: _FakeUsersBackendClient(),
        );

        await controller.bootstrap();
        expect(controller.users, hasLength(2));

        final created = await controller.createUser(
          login: 'master-2',
          password: 'master234',
          role: 'master',
          displayName: 'Master Two',
        );
        expect(created, isTrue);
        expect(controller.users, hasLength(3));
        expect(
          controller.users.any((user) => user.login == 'master-2'),
          isTrue,
        );

        final createdUser = controller.users.firstWhere(
          (user) => user.login == 'master-2',
        );
        await controller.resetPassword(
          userId: createdUser.id,
          newPassword: 'master999',
        );
        expect(controller.successMessage, contains('Password was reset'));

        await controller.deactivateUser(createdUser.id);
        final deactivatedUser = controller.users.firstWhere(
          (user) => user.id == createdUser.id,
        );
        expect(deactivatedUser.isActive, isFalse);
        expect(controller.errorMessage, isNull);
      },
    );
  });
}

class _FakeUsersBackendClient implements AdminBackendClient {
  final List<UserSummaryDto> _users = [
    UserSummaryDto(
      id: 'planner-1',
      login: 'planner-1',
      role: 'planner',
      displayName: 'Planner One',
      isActive: true,
      createdAt: DateTime.utc(2026, 3, 1, 8),
    ),
    UserSummaryDto(
      id: 'supervisor-1',
      login: 'supervisor-1',
      role: 'supervisor',
      displayName: 'Supervisor One',
      isActive: true,
      createdAt: DateTime.utc(2026, 3, 1, 8, 30),
    ),
  ];
  int _sequence = 1;

  @override
  Future<ApiListResponseDto<UserSummaryDto>> listUsers() async {
    return ApiListResponseDto(
      items: List<UserSummaryDto>.from(_users),
      meta: const {'resource': 'users'},
    );
  }

  @override
  Future<UserSummaryDto> createUser(CreateUserRequestDto request) async {
    _sequence += 1;
    final user = UserSummaryDto(
      id: 'user-$_sequence',
      login: request.login,
      role: request.role,
      displayName: request.displayName,
      isActive: true,
      createdAt: DateTime.utc(2026, 4, 2, 9, _sequence),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<UserSummaryDto> deactivateUser(
    String userId,
    RequestIdDto request,
  ) async {
    final index = _users.indexWhere((user) => user.id == userId);
    final updated = UserSummaryDto(
      id: _users[index].id,
      login: _users[index].login,
      role: _users[index].role,
      displayName: _users[index].displayName,
      isActive: false,
      createdAt: _users[index].createdAt,
    );
    _users[index] = updated;
    return updated;
  }

  @override
  Future<UserSummaryDto> resetUserPassword(
    String userId,
    ResetPasswordRequestDto request,
  ) async {
    return _users.firstWhere((user) => user.id == userId);
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
