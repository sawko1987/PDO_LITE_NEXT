import 'master_outbox_item.dart';

abstract interface class MasterOutboxRepository {
  Future<List<MasterOutboxItem>> loadItems();

  Future<void> saveItems(List<MasterOutboxItem> items);
}
