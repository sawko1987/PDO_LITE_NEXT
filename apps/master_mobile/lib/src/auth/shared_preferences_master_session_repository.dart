import 'dart:convert';

import 'package:data_models/data_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'master_session_repository.dart';

class SharedPreferencesMasterSessionRepository
    implements MasterSessionRepository {
  SharedPreferencesMasterSessionRepository(this._preferences);

  static const _storageKey = 'master_auth_session_v1';

  final SharedPreferences _preferences;

  @override
  Future<void> clearSession() async {
    await _preferences.remove(_storageKey);
  }

  @override
  Future<LoginResponseDto?> loadSession() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return null;
    }

    return LoginResponseDto.fromJson(decoded);
  }

  @override
  Future<void> saveSession(LoginResponseDto session) async {
    await _preferences.setString(_storageKey, jsonEncode(session.toJson()));
  }
}
