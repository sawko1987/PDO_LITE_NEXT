class CreateUserRequestDto {
  const CreateUserRequestDto({
    required this.requestId,
    required this.login,
    required this.password,
    required this.role,
    required this.displayName,
  });

  factory CreateUserRequestDto.fromJson(Map<String, Object?> json) {
    return CreateUserRequestDto(
      requestId: json['requestId'] as String? ?? '',
      login: json['login'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: json['role'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }

  final String requestId;
  final String login;
  final String password;
  final String role;
  final String displayName;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'login': login,
    'password': password,
    'role': role,
    'displayName': displayName,
  };
}
