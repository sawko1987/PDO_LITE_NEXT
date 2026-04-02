import 'package:domain/domain.dart';

class UserSummaryDto {
  const UserSummaryDto({
    required this.id,
    required this.login,
    required this.role,
    required this.displayName,
    required this.isActive,
    required this.createdAt,
  });

  factory UserSummaryDto.fromDomain(User user) {
    return UserSummaryDto(
      id: user.id,
      login: user.login,
      role: user.role.name,
      displayName: user.displayName,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
  }

  factory UserSummaryDto.fromJson(Map<String, Object?> json) {
    return UserSummaryDto(
      id: json['id'] as String? ?? '',
      login: json['login'] as String? ?? '',
      role: json['role'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
    );
  }

  final String id;
  final String login;
  final String role;
  final String displayName;
  final bool isActive;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'login': login,
    'role': role,
    'displayName': displayName,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };
}
