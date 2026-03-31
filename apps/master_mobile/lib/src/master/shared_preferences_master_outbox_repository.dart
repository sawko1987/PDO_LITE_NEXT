import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'master_outbox_item.dart';
import 'master_outbox_repository.dart';

class SharedPreferencesMasterOutboxRepository
    implements MasterOutboxRepository {
  SharedPreferencesMasterOutboxRepository(this._preferences);

  static const _storageKey = 'master_outbox_items_v1';

  final SharedPreferences _preferences;

  @override
  Future<List<MasterOutboxItem>> loadItems() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      return const [];
    }

    return decoded
        .whereType<Map<Object?, Object?>>()
        .map((item) => MasterOutboxItem.fromJson(item.cast<String, Object?>()))
        .toList(growable: false);
  }

  @override
  Future<void> saveItems(List<MasterOutboxItem> items) async {
    final payload = jsonEncode(items.map((item) => item.toJson()).toList());
    await _preferences.setString(_storageKey, payload);
  }
}
