import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/settings/backup_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupController', () {
    test(
      'bootstrap loads diagnostics and backup operations refresh state',
      () async {
        final controller = BackupController(
          client: _FakeBackupBackendClient(),
          currentUserId: 'planner-1',
        );

        await controller.bootstrap();

        expect(controller.health?.status, 'ok');
        expect(controller.backups, hasLength(1));
        expect(controller.idempotencyStats?.totalRecords, 2);

        await controller.createBackup();
        expect(controller.backups.first.fileName, 'backup-2.sqlite3');
        expect(controller.successMessage, contains('backup-2.sqlite3'));

        await controller.restoreBackup('backup-2.sqlite3');
        expect(controller.successMessage, contains('backup-2.sqlite3'));
        expect(controller.errorMessage, isNull);
      },
    );
  });
}

class _FakeBackupBackendClient implements AdminBackendClient {
  final List<BackupInfoDto> _backups = [
    BackupInfoDto(
      backupId: 'backup-1',
      fileName: 'backup-1.sqlite3',
      createdAt: DateTime.utc(2026, 4, 1, 9),
      sizeBytes: 2048,
      status: 'ready',
    ),
  ];
  int _sequence = 1;

  @override
  Future<HealthExtendedDto> getHealthExtended() async {
    return HealthExtendedDto(
      status: 'ok',
      service: 'pdo_lite_next_backend',
      timestamp: DateTime.utc(2026, 4, 2, 9),
      databasePath: 'C:/pdo_lite_next.sqlite3',
      databaseSizeBytes: 2048,
      totalMachines: 1,
      totalPlans: 3,
      totalTasks: 3,
      totalAuditEntries: 4,
      lastAuditAt: DateTime.utc(2026, 4, 2, 8, 30),
      uptime: '2:15:00.000000',
    );
  }

  @override
  Future<IdempotencyStatsDto> getIdempotencyStats() async {
    return const IdempotencyStatsDto(
      totalRecords: 2,
      byCategory: [
        IdempotencyCategoryStatDto(category: 'backup_create', count: 1),
        IdempotencyCategoryStatDto(category: 'backup_restore', count: 1),
      ],
    );
  }

  @override
  Future<ApiListResponseDto<BackupInfoDto>> listBackups() async {
    return ApiListResponseDto(
      items: List<BackupInfoDto>.from(_backups.reversed),
      meta: const {'resource': 'backups'},
    );
  }

  @override
  Future<BackupInfoDto> createBackup(CreateBackupRequestDto request) async {
    _sequence += 1;
    final backup = BackupInfoDto(
      backupId: 'backup-$_sequence',
      fileName: 'backup-$_sequence.sqlite3',
      createdAt: DateTime.utc(2026, 4, 2, 10, _sequence),
      sizeBytes: 4096,
      status: 'ready',
    );
    _backups.add(backup);
    return backup;
  }

  @override
  Future<RestoreBackupResponseDto> restoreBackup(
    RestoreBackupRequestDto request,
  ) async {
    return RestoreBackupResponseDto(
      status: 'restored',
      restoredAt: DateTime.utc(2026, 4, 2, 11),
    );
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
