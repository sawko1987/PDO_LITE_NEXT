class LoginRequestDto {
  const LoginRequestDto({required this.login, required this.password});

  factory LoginRequestDto.fromJson(Map<String, Object?> json) {
    return LoginRequestDto(
      login: json['login'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  final String login;
  final String password;

  Map<String, Object?> toJson() => {'login': login, 'password': password};
}
