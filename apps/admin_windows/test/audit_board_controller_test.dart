import 'package:admin_windows/src/audit/audit_board_controller.dart';
import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditBoardController', () {
    test('bootstrap loads audit entries and CSV export matches rows', () async {
      final controller = AuditBoardController(
        client: _FakeAuditBackendClient(),
      );

      await controller.bootstrap();

      expect(controller.entries, hasLength(1));
      expect(controller.total, 1);
      expect(controller.users, hasLength(1));

      final csv = controller.buildCsv();
      expect(csv, contains('changedAt,changedBy,entityType'));
      expect(csv, contains('"planner-1"'));
      expect(csv, contains('"archived"'));
    });
  });
}

class _FakeAuditBackendClient implements AdminBackendClient {
  @override
  Future<ApiListResponseDto<UserSummaryDto>> listUsers() async {
    return ApiListResponseDto(
      items: [
        UserSummaryDto(
          id: 'planner-1',
          login: 'planner-1',
          role: 'planner',
          displayName: 'Planner One',
          isActive: true,
          createdAt: DateTime.utc(2026, 3, 1, 8),
        ),
      ],
      meta: const {'resource': 'users'},
    );
  }

  @override
  Future<ApiListResponseDto<AuditEntryDto>> listAuditEntries({
    String? entityType,
    String? entityId,
    String? action,
    String? changedBy,
    String? fromDate,
    String? toDate,
    int? limit,
    int? offset,
  }) async {
    return ApiListResponseDto(
      items: [
        AuditEntryDto(
          id: 'audit-1',
          entityType: entityType ?? 'plan',
          entityId: entityId ?? 'plan-2',
          action: action ?? 'archived',
          changedBy: changedBy ?? 'planner-1',
          changedAt: DateTime.utc(2026, 3, 27, 15, 30),
          field: 'status',
          beforeValue: 'released',
          afterValue: 'completed',
        ),
      ],
      total: 1,
      meta: const {'resource': 'audit_entries'},
    );
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
