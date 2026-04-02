import 'user_role.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.role,
    required this.expiresAt,
  });

  final String token;
  final String userId;
  final UserRole role;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());
}
