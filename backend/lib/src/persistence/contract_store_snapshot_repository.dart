import '../store/contract_store_snapshot.dart';

abstract interface class ContractStoreSnapshotRepository {
  ContractStoreSnapshot loadOrSeed(ContractStoreSnapshot seedSnapshot);

  void save(ContractStoreSnapshot snapshot);

  String get databasePath;

  int getDatabaseSizeBytes();

  BackupFileRecord createBackup({required String backupFileName});

  List<BackupFileRecord> listBackups();

  RestoreBackupResult restoreBackup({required String backupFileName});
}

class BackupFileRecord {
  const BackupFileRecord({
    required this.backupId,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    required this.status,
  });

  final String backupId;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final String status;
}

class RestoreBackupResult {
  const RestoreBackupResult({required this.restoredAt});

  final DateTime restoredAt;
}
