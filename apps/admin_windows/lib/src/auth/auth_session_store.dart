import 'dart:convert';
import 'dart:io';

import 'package:data_models/data_models.dart';

class AuthSessionStore {
  Future<LoginResponseDto?> load() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final session = LoginResponseDto.fromJson(
        decoded.cast<String, Object?>(),
      );
      if (session.expiresAt.isBefore(DateTime.now().toUtc())) {
        await clear();
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LoginResponseDto session) async {
    final file = await _sessionFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(session.toJson()), flush: true);
  }

  Future<void> clear() async {
    final file = await _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _sessionFile() async {
    final appData =
        Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return File('$appData\\PDO_LITE_NEXT\\admin_windows_session.json');
  }
}
