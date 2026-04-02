class RestoreBackupRequestDto {
  const RestoreBackupRequestDto({
    required this.requestId,
    required this.backupFileName,
  });

  factory RestoreBackupRequestDto.fromJson(Map<String, Object?> json) {
    return RestoreBackupRequestDto(
      requestId: json['requestId'] as String? ?? '',
      backupFileName: json['backupFileName'] as String? ?? '',
    );
  }

  final String requestId;
  final String backupFileName;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'backupFileName': backupFileName,
  };
}
