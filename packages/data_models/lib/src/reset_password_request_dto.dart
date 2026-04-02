class ResetPasswordRequestDto {
  const ResetPasswordRequestDto({
    required this.requestId,
    required this.newPassword,
  });

  factory ResetPasswordRequestDto.fromJson(Map<String, Object?> json) {
    return ResetPasswordRequestDto(
      requestId: json['requestId'] as String? ?? '',
      newPassword: json['newPassword'] as String? ?? '',
    );
  }

  final String requestId;
  final String newPassword;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'newPassword': newPassword,
  };
}
