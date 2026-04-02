import '../store/contract_store_snapshot.dart';

abstract interface class ContractStoreSnapshotRepository {
  ContractStoreSnapshot loadOrSeed(ContractStoreSnapshot seedSnapshot);

  void save(ContractStoreSnapshot snapshot);
}
