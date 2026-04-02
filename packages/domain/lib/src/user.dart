import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.login,
    required this.passwordHash,
    required this.role,
    required this.displayName,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String login;
  final String passwordHash;
  final UserRole role;
  final String displayName;
  final bool isActive;
  final DateTime createdAt;
}
