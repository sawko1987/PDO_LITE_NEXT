import 'package:data_models/data_models.dart';

abstract interface class MasterSessionRepository {
  Future<LoginResponseDto?> loadSession();

  Future<void> saveSession(LoginResponseDto session);

  Future<void> clearSession();
}
