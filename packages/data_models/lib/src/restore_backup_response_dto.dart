class RestoreBackupResponseDto {
  const RestoreBackupResponseDto({
    required this.status,
    required this.restoredAt,
  });

  factory RestoreBackupResponseDto.fromJson(Map<String, Object?> json) {
    return RestoreBackupResponseDto(
      status: json['status'] as String? ?? '',
      restoredAt: DateTime.parse(json['restoredAt'] as String),
    );
  }

  final String status;
  final DateTime restoredAt;

  Map<String, Object?> toJson() => {
    'status': status,
    'restoredAt': restoredAt.toIso8601String(),
  };
}
