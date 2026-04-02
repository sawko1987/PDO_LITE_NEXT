class LoginResponseDto {
  const LoginResponseDto({
    required this.token,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.expiresAt,
  });

  factory LoginResponseDto.fromJson(Map<String, Object?> json) {
    return LoginResponseDto(
      token: json['token'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      expiresAt: DateTime.parse(
        json['expiresAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
    );
  }

  final String token;
  final String userId;
  final String role;
  final String displayName;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
    'token': token,
    'userId': userId,
    'role': role,
    'displayName': displayName,
    'expiresAt': expiresAt.toIso8601String(),
  };
}
